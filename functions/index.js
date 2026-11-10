const functions = require("firebase-functions");
const { onCall } = require("firebase-functions/v2/https");
const crypto = require("crypto");
const { v4: uuidv4 } = require("uuid");
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

// Initialiser Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// ── App Store promo offer signing ─────────────────────────────────────────────
const KEY_ID = "ZQF632P8J4";
const BUNDLE_ID = "com.royrotvold.bonusvarsel";

function loadPrivateKey() {
  const keyPath = path.join(__dirname, "keys", "SubscriptionKey.p8");
  return fs.readFileSync(keyPath, "utf8");
}

exports.signPromoOffer = functions.https.onCall(async (data, context) => {
  if (!context || !context.auth) throw new functions.https.HttpsError("unauthenticated", "Innlogging kreves.");
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Må være innlogget.");
  }

  const { productId, offerId } = data;
  if (!productId || !offerId) {
    throw new functions.https.HttpsError("invalid-argument", "productId og offerId er påkrevd.");
  }

  const nonce = uuidv4().toLowerCase();
  const timestamp = Date.now();
  const payload = `${BUNDLE_ID}\u2063${KEY_ID}\u2063${productId}\u2063${offerId}\u2063${nonce}\u2063${timestamp}`;

  const privateKey = loadPrivateKey();
  const sign = crypto.createSign("SHA256");
  sign.update(payload);
  sign.end();
  const signature = sign.sign({ key: privateKey, dsaEncoding: "ieee-p1363" }, "base64");

  return { keyId: KEY_ID, nonce, timestamp, signature };
});

// ── Stripe webhook ────────────────────────────────────────────────────────────
const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;

exports.stripeWebhook = functions.https.onRequest(
  { secrets: ["STRIPE_WEBHOOK_SECRET", "STRIPE_EVENTS_KEY"] },
  async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const payload = req.rawBody;

  // Verifiser Stripe signatur
  let event;
  try {
    // STRIPE_SIG_FIX_V1: sjekk alle v1-signaturer, tidstoleranse 5 min, konstant-tid sammenligning
    const parts = sig.split(",").map((p) => p.split("="));
    const t = parts.find(([k]) => k === "t")?.[1];
    const v1s = parts.filter(([k]) => k === "v1").map(([, v]) => v);
    if (!t || v1s.length === 0) {
      return res.status(400).send("Mangler signatur");
    }
    if (Math.abs(Date.now() / 1000 - Number(t)) > 300) {
      return res.status(400).send("Signatur for gammel");
    }
    const expected = crypto.createHmac("sha256", STRIPE_WEBHOOK_SECRET)
      .update(`${t}.${payload}`).digest("hex");
    const ok = v1s.some((v) =>
      v.length === expected.length &&
      crypto.timingSafeEqual(Buffer.from(v), Buffer.from(expected)));
    if (!ok) {
      console.error("Stripe signatur feil");
      return res.status(400).send("Ugyldig signatur");
    }

    event = JSON.parse(payload);

    // THIN_FETCH_FIX_V1: v2-hendelser (Account Person osv.) ignoreres. Thin-hendelser
    // mangler data.object, derfor hentes hele hendelsen fra Stripe.
    if (String(event.type || "").startsWith("v2.")) {
      return res.status(200).send("OK");
    }
    // THIN_RELATED_FIX_V1: hent objektet hendelsen peker til (related_object.url) og bygg hendelsen selv
    if (!event.data || !event.data.object) {
      const relUrl = event.related_object && event.related_object.url;
      if (!relUrl) {
        return res.status(200).send("OK");
      }
      const r = await fetch(`https://api.stripe.com${relUrl}`, {
        headers: { Authorization: `Bearer ${process.env.STRIPE_EVENTS_KEY}` },
      });
      if (!r.ok) {
        console.error("Kunne ikke hente objekt fra Stripe:", r.status, relUrl);
        return res.status(500).send("Kunne ikke hente objekt");
      }
      const obj = await r.json();
      event = {
        id: event.id,
        type: String(event.type).replace(/^v1\./, ""),
        data: { object: obj },
      };
    }
  } catch (err) {
    console.error("Webhook feil:", err);
    return res.status(400).send(`Webhook feil: ${err.message}`);
  }

  // Håndter invoice.paid (abonnement betalt)
  if (event.type === "invoice.paid") {
    const invoice = event.data.object;
    const email = invoice.customer_email;
    const amount = invoice.amount_paid; // i øre
    const description = invoice.lines?.data?.[0]?.description || '';

    if (!email) {
      console.error("Ingen e-post i invoice");
      return res.status(200).send("OK");
    }

    let plan = "premium";
    if (amount >= 8900 || description.toLowerCase().includes('elite')) plan = "elite";
    console.log(`invoice.paid: Aktiverer ${plan} for ${email}, beløp: ${amount}, desc: ${description}`);

    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      await db.collection("subscriptions").doc(userRecord.uid).set({
        plan,
        email,
        source: "stripe_web",
        stripeCustomerId: invoice.customer || null,
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log(`✅ ${plan} aktivert for ${email}`);
      return res.status(200).send("OK");
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        await db.collection("pending_subscriptions").doc(email.toLowerCase()).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`⏳ Pending ${plan} for ${email}`);
        return res.status(200).send("OK");
      }
      console.error("Feil ved aktivering:", err);
      return res.status(500).send("Feil");
    }
  }

  // Håndter checkout.session.completed
  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const email = session.customer_details?.email || session.customer_email;
    const priceId = session.line_items?.data?.[0]?.price?.id;
    const description = session.line_items?.data?.[0]?.description || '';

    if (!email) {
      console.error("Ingen e-post i session");
      return res.status(200).send("OK");
    }

    // Bestem plan basert på beløp eller price ID
    // STRIPE_WEBHOOK_FIX_V1: 'description' var tidligere udeklarert her og
    // kastet ReferenceError for kjøp under 89 kr.
    const amount = session.amount_total;
    let plan = "premium";
    if (amount >= 8900 || description.toLowerCase().includes('elite')) plan = "elite";

    console.log(`Aktiverer ${plan} for ${email}`);

    try {
      // STRIPE_REFID_V1: bruk client_reference_id (uid fra appen) først, e-post som reserve
      let userRecord = null;
      if (session.client_reference_id) {
        userRecord = await admin.auth().getUser(String(session.client_reference_id)).catch(() => null);
      }
      if (!userRecord) {
        userRecord = await admin.auth().getUserByEmail(email).catch(() => null);
      }

      if (userRecord) {
        // Lagre plan i Firestore
        await db.collection("subscriptions").doc(userRecord.uid).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          stripeCustomerId: session.customer || null,
          source: "stripe_web",
        }, { merge: true });

        console.log(`✅ ${plan} aktivert for uid: ${userRecord.uid}`);
      } else {
        // Bruker finnes ikke ennå — lagre med e-post som nøkkel
        await db.collection("pending_subscriptions").doc(email.toLowerCase()).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          stripeCustomerId: session.customer || null,
          source: "stripe_web",
        }, { merge: true });

        console.log(`⏳ Pending ${plan} for ${email} (ikke registrert ennå)`);
      }
    } catch (err) {
      console.error("Firestore feil:", err);
    }
  }

  // Håndter customer.subscription.deleted (avmelding)
  // STRIPE_WEBHOOK_FIX_V1: subscription.customer_email finnes ikke på Stripe
  // sitt subscription-objekt, så nedgradering skjedde aldri før. Slår nå opp
  // via stripeCustomerId, som lagres på aktivering (invoice.paid /
  // checkout.session.completed).
  if (event.type === "customer.subscription.deleted") {
    const subscription = event.data.object;
    const customerId = subscription.customer;
    const emailFallback = subscription.customer_email || null;

    try {
      let uid = null;

      if (customerId) {
        const snap = await db.collection("subscriptions")
          .where("stripeCustomerId", "==", customerId)
          .limit(1)
          .get();
        if (!snap.empty) uid = snap.docs[0].id;
      }
      if (!uid && emailFallback) {
        const userRecord = await admin.auth().getUserByEmail(emailFallback).catch(() => null);
        if (userRecord) uid = userRecord.uid;
      }

      if (!uid) {
        console.error(`[stripeWebhook] Fant ikke bruker for kansellert abonnement, customerId=${customerId}`);
      } else {
        const subRef = db.collection("subscriptions").doc(uid);
        const existingSnap = await subRef.get();
        const existing = existingSnap.exists ? existingSnap.data() : null;
        const playStillActive =
          existing &&
          existing.source === "google_play" &&
          existing.playExpiryTime &&
          existing.playExpiryTime.toMillis() > Date.now();

        const appStoreStillActive =
          existing &&
          existing.source === "app_store" &&
          existing.appStoreExpiryTime &&
          existing.appStoreExpiryTime.toMillis() > Date.now();

        if (playStillActive || appStoreStillActive) {
          console.log(`[stripeWebhook] Stripe kansellert for uid ${uid}, men aktivt Google Play-abonnement beholdes`);
        } else {
          await subRef.set({
            plan: "free",
            source: "stripe_web",
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          console.log(`❌ Abonnement kansellert for uid ${uid} (customer ${customerId})`);
        }
      }
    } catch (err) {
      console.error("Feil ved kansellering:", err);
    }
  }

  // PENDING_CANCEL_FIX_V1: fjern tilgang for kjop gjort for konto fantes, nar Stripe-abonnementet avsluttes
  if (event.type === "customer.subscription.deleted") {
    try {
      const customerId = event.data.object.customer;
      if (customerId) {
        const pendSnap = await db.collection("pending_subscriptions")
          .where("stripeCustomerId", "==", customerId).get();
        for (const d of pendSnap.docs) {
          await d.ref.set({
            plan: "free",
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          console.log(`Pending-tilgang fjernet for ${d.id} (customer ${customerId})`);
        }
      }
    } catch (err) {
      console.error("Feil ved pending-kansellering:", err);
    }
  }

  // MULTI_UID_CANCEL_V1: flere brukere kan dele samme Stripe-kunde (kjøp via uid og via e-post).
  // Fjern tilgangen på alle Stripe-dokumenter for kunden når abonnementet avsluttes.
  if (event.type === "customer.subscription.deleted") {
    try {
      const customerId = event.data.object.customer;
      if (customerId) {
        const all = await db.collection("subscriptions")
          .where("stripeCustomerId", "==", customerId).get();
        for (const d of all.docs) {
          const x = d.data();
          if (x.source === "stripe_web" && x.plan !== "free") {
            await d.ref.set({
              plan: "free",
              cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            console.log(`Stripe-tilgang fjernet for uid ${d.id} (customer ${customerId})`);
          }
        }
      }
    } catch (err) {
      console.error("Feil ved fjerning av alle Stripe-dokumenter:", err);
    }
  }

  res.status(200).send("OK");
});

// ── Sjekk abonnement ──────────────────────────────────────────────────────────
exports.checkSubscription = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) return { plan: 'free' };

  try {
    const doc = await db.collection('subscriptions').doc(auth.uid).get();

    if (doc.exists) {
      // PLAY_EXPIRY_GUARD
      const subData = doc.data();
      if (subData.source === 'google_play' && subData.playExpiryTime && subData.playExpiryTime.toMillis() < Date.now()) {
        return { plan: 'free' };
      }
      if (subData.source === 'app_store' && subData.appStoreExpiryTime && subData.appStoreExpiryTime.toMillis() < Date.now()) {
        return { plan: 'free' };
      }
      return { plan: subData.plan || 'free' };
    }
    const email = auth.token?.email;
    if (email) {
      const pending = await db.collection('pending_subscriptions')
        .doc(email.toLowerCase()).get();
      if (pending.exists) {
        return { plan: pending.data().plan || 'free' };
      }
    }
    return { plan: 'free' };
  } catch (e) {
    console.error('[checkSubscription] Feil:', e.message);
    return { plan: 'free' };
  }
});

// ── Claude AI Proxy ────────────────────────────────────────────────────────
exports.callClaude = functions.https.onCall(
  { secrets: ["ANTHROPIC_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Logg inn først.");
    }

    try {
      const { messages, maxTokens = 1000 } = request.data;
      const model = "claude-sonnet-5";

      console.log("[callClaude] request", {
        hasApiKey: Boolean(process.env.ANTHROPIC_API_KEY),
        model,
        maxTokens,
        messageCount: Array.isArray(messages) ? messages.length : null,
      });

      const fetch = require("node-fetch");

      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": process.env.ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model,
          max_tokens: maxTokens,
          messages,
        }),
      });

      if (!response.ok) {
        const err = await response.text();
        console.error("[callClaude] Anthropic API-feil", {
          status: response.status,
          statusText: response.statusText,
          body: err,
        });
        throw new functions.https.HttpsError("internal", `Claude feil (${response.status}): ${err}`);
      }

      const result = await response.json();
      // claude-sonnet-5 kan returnere en "thinking"-blokk FØR selve tekstsvaret.
      // Hent riktig blokk basert på type, ikke bare første element i listen -
      // ellers blir "content" null/undefined og appen krasjer med en type-cast-feil.
      const textBlock = (result.content || []).find((b) => b.type === "text");
      if (!textBlock) {
        console.error("[callClaude] Fant ingen tekstblokk i svaret", { content: result.content });
        throw new functions.https.HttpsError("internal", "Claude returnerte ingen tekst.");
      }
      console.log("[callClaude] suksess");
      return { content: textBlock.text };
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      console.error("[callClaude] Uventet feil", {
        message: e && e.message,
        stack: e && e.stack,
      });
      throw new functions.https.HttpsError("internal", `Uventet feil: ${e && e.message}`);
    }
  }
);


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

// Flying Agent (SAS/SkyTeam/Flying Blue/Avios/Norwegian)
exports.flyingAgent = require("./flying_agent").flyingAgent;

exports.importBalance = require("./balance_import").importBalance;

exports.verifyAppStorePurchase = require("./appstore_verify").verifyAppStorePurchase;
