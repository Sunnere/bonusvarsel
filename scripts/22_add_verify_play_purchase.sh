#!/usr/bin/env bash
set -euo pipefail

TARGET="functions/index.js"
BACKUP_DIR="scripts/backups"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "=== 1) Forhåndssjekker ==="
if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET. Kjør fra roten av bonusvarsel-repoet."
  exit 1
fi
if grep -q "exports.verifyPlayPurchase" "$TARGET"; then
  echo "✅ verifyPlayPurchase finnes allerede i $TARGET — ingenting å gjøre."
  exit 0
fi
if grep -q "exports.checkSubscription" "$TARGET"; then
  echo "✅ checkSubscription funnet"
else
  echo "❌ checkSubscription ikke funnet i $TARGET — avbryter uten endringer."
  exit 1
fi

echo "=== 2) Backup ==="
mkdir -p "$BACKUP_DIR"
cp "$TARGET" "$BACKUP_DIR/index.js.$STAMP.bak"
echo "✅ Backup: $BACKUP_DIR/index.js.$STAMP.bak"

echo "=== 3) Legger til verifyPlayPurchase på slutten av $TARGET ==="
cat >> "$TARGET" << 'JS_EOF'


// ── Google Play IAP-verifisering (Android) ────────────────────────────────────
// Kalles fra Flutter etter vellykket kjøp/restore på Android.
// Verifiserer purchaseToken mot Google Play Developer API og skriver til
// Firestore subscriptions/{uid} med source: "google_play".
const { HttpsError: PlayHttpsError } = require("firebase-functions/v2/https");

const PLAY_PACKAGE_NAME = "com.bonusvarsel.minapp";
const PLAN_RANK = { free: 0, premium: 1, elite: 2 };
const PLAY_ACTIVE_STATES = [
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
];
const PLAY_GRACE_MS = 3 * 24 * 60 * 60 * 1000;

// Samme logikk som Stripe-webhooken: "elite" i produkt-ID => elite, ellers premium.
function planFromPlayProduct(productId) {
  const id = String(productId || "").toLowerCase();
  if (id.includes("elite")) return "elite";
  return "premium";
}

async function getPlayAccessToken() {
  const { GoogleAuth } = require("google-auth-library");
  const credentials = JSON.parse(process.env.PLAY_SERVICE_ACCOUNT);
  const gAuth = new GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await gAuth.getClient();
  const tokenResponse = await client.getAccessToken();
  return tokenResponse.token;
}

exports.verifyPlayPurchase = onCall(
  { secrets: ["PLAY_SERVICE_ACCOUNT"] },
  async (request) => {
    const auth = request.auth;
    if (auth == null) {
      throw new PlayHttpsError("unauthenticated", "Må være innlogget.");
    }

    const purchaseToken = request.data ? request.data.purchaseToken : null;
    if (typeof purchaseToken !== "string" || purchaseToken.length < 20 || purchaseToken.length > 2000) {
      throw new PlayHttpsError("invalid-argument", "Ugyldig purchaseToken.");
    }

    // Ett kjøp kan bare kobles til én konto
    const tokenHash = crypto.createHash("sha256").update(purchaseToken).digest("hex");
    const tokenRef = db.collection("play_purchases").doc(tokenHash);
    const tokenSnap = await tokenRef.get();
    if (tokenSnap.exists && tokenSnap.data().uid !== auth.uid) {
      console.error(`[verifyPlayPurchase] Token allerede brukt av annen uid. Forsøk fra ${auth.uid}`);
      throw new PlayHttpsError("already-exists", "Kjøpet er allerede koblet til en annen konto.");
    }

    // Spør Google
    let sub;
    try {
      const accessToken = await getPlayAccessToken();
      const url =
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" +
        PLAY_PACKAGE_NAME +
        "/purchases/subscriptionsv2/tokens/" +
        encodeURIComponent(purchaseToken);
      const resp = await fetch(url, {
        headers: { Authorization: "Bearer " + accessToken },
      });
      if (resp.ok === false) {
        const body = await resp.text();
        console.error(`[verifyPlayPurchase] Google svarte ${resp.status}: ${body.slice(0, 300)}`);
        if (resp.status === 404 || resp.status === 410 || resp.status === 400) {
          throw new PlayHttpsError("not-found", "Kjøpet ble ikke funnet hos Google Play.");
        }
        throw new PlayHttpsError("internal", "Kunne ikke verifisere kjøpet hos Google Play.");
      }
      sub = await resp.json();
    } catch (e) {
      if (e instanceof PlayHttpsError) throw e;
      console.error("[verifyPlayPurchase] Feil mot Google:", e.message);
      throw new PlayHttpsError("internal", "Kunne ikke verifisere kjøpet.");
    }

    const lineItem = (sub.lineItems || [])[0] || {};
    const productId = lineItem.productId || null;
    const expiry = lineItem.expiryTime ? new Date(lineItem.expiryTime) : null;
    const state = sub.subscriptionState || "";
    const notExpired = expiry != null && expiry.getTime() > Date.now();
    const active =
      PLAY_ACTIVE_STATES.includes(state) ||
      (state === "SUBSCRIPTION_STATE_CANCELED" && notExpired);

    // Koble token til uid
    await tokenRef.set(
      {
        uid: auth.uid,
        productId,
        state,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const subRef = db.collection("subscriptions").doc(auth.uid);
    const existingSnap = await subRef.get();
    const existing = existingSnap.exists ? existingSnap.data() : null;
    const expiresAtIso = expiry ? expiry.toISOString() : null;

    if (active) {
      const plan = planFromPlayProduct(productId);

      // Ikke nedgrader en aktiv Stripe/web-plan med et lavere Play-kjøp
      if (
        existing != null &&
        existing.source !== "google_play" &&
        (PLAN_RANK[existing.plan] || 0) >= PLAN_RANK[plan]
      ) {
        return { plan: existing.plan, active: true, keptExisting: true, expiresAt: expiresAtIso };
      }

      // I grace period kan expiryTime være passert — gi 3 dager til klienten verifiserer på nytt
      let effectiveExpiryMs = expiry ? expiry.getTime() : Date.now() + PLAY_GRACE_MS;
      if (state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
        effectiveExpiryMs = Math.max(effectiveExpiryMs, Date.now() + PLAY_GRACE_MS);
      }

      const data = {
        plan,
        email: (auth.token && auth.token.email) || (existing && existing.email) || null,
        source: "google_play",
        playProductId: productId,
        playSubscriptionState: state,
        playTokenHash: tokenHash,
        playExpiryTime: admin.firestore.Timestamp.fromDate(new Date(effectiveExpiryMs)),
        playLastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (existing == null || existing.source !== "google_play") {
        data.activatedAt = admin.firestore.FieldValue.serverTimestamp();
      }
      await subRef.set(data, { merge: true });
      console.log(`✅ Play: ${plan} aktivert for uid ${auth.uid} (${productId}, ${state})`);
      return { plan, active: true, expiresAt: expiresAtIso };
    }

    // Ikke aktivt: nedgrader bare hvis Firestore-planen kom fra akkurat dette Play-kjøpet
    if (existing != null && existing.source === "google_play" && existing.playTokenHash === tokenHash) {
      await subRef.set(
        {
          plan: "free",
          playSubscriptionState: state,
          playLastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      console.log(`❌ Play: abonnement ikke aktivt (${state}) for uid ${auth.uid}`);
      return { plan: "free", active: false, expiresAt: expiresAtIso };
    }
    return { plan: (existing && existing.plan) || "free", active: false, expiresAt: expiresAtIso };
  }
);
JS_EOF
echo "✅ verifyPlayPurchase lagt til"

echo "=== 4) Utløpssjekk i checkSubscription ==="
node - << 'NODE_EOF'
const fs = require("fs");
const file = "functions/index.js";
let src = fs.readFileSync(file, "utf8");
const marker = "// PLAY_EXPIRY_GUARD";
if (src.includes(marker)) {
  console.log("✅ Utløpssjekk finnes allerede — hopper over");
  process.exit(0);
}
const old = "return { plan: doc.data().plan || 'free' };";
const count = src.split(old).length - 1;
if (count !== 1) {
  console.error("❌ Forventet nøyaktig 1 treff på checkSubscription-linjen, fant " + count);
  process.exit(1);
}
const neu =
  marker + "\n" +
  "      const subData = doc.data();\n" +
  "      if (subData.source === 'google_play' && subData.playExpiryTime && subData.playExpiryTime.toMillis() < Date.now()) {\n" +
  "        return { plan: 'free' };\n" +
  "      }\n" +
  "      return { plan: subData.plan || 'free' };";
src = src.replace(old, function () { return neu; });
fs.writeFileSync(file, src);
console.log("✅ checkSubscription patchet");
NODE_EOF

echo "=== 5) Installerer google-auth-library i functions/ ==="
(cd functions && npm install google-auth-library --save --silent)
echo "✅ google-auth-library installert"

echo "=== 6) Syntakssjekk ==="
if node --check "$TARGET"; then
  echo "✅ Syntaks OK"
else
  echo "❌ Syntaksfeil — gjenoppretter backup"
  cp "$BACKUP_DIR/index.js.$STAMP.bak" "$TARGET"
  exit 1
fi

echo ""
echo "=== Produkt-ID-er i Flutter (bekreft at 'elite' står i ID-en for Elite-produktet) ==="
grep -rn -i "productid\|product_id\|_productIds\|kProductIds\|subscriptionIds" lib/ 2>/dev/null | head -20 || echo "(ingen treff i lib/)"

echo ""
echo "=== Ferdig ==="
echo "Neste:"
echo "  1) firebase functions:secrets:set PLAY_SERVICE_ACCOUNT --data-file ~/Downloads/DIN-NOKKEL.json"
echo "  2) firebase deploy --only functions:verifyPlayPurchase,functions:checkSubscription"
