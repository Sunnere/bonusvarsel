const functions = require("firebase-functions");
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
const KEY_ID = "WNU3742ZH9";
const BUNDLE_ID = "com.royrotvold.bonusvarsel";

function loadPrivateKey() {
  const keyPath = path.join(__dirname, "keys", "SubscriptionKey.p8");
  return fs.readFileSync(keyPath, "utf8");
}

exports.signPromoOffer = functions.https.onCall(async (data, context) => {
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
const STRIPE_WEBHOOK_SECRET = "whsec_e3S9LZHMC8VwDNwHdvXu8B5UPsxYzskM";

exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const payload = req.rawBody;

  // Verifiser Stripe signatur
  let event;
  try {
    const hmac = crypto.createHmac("sha256", STRIPE_WEBHOOK_SECRET);
    const [t, v1] = sig.split(",").reduce((acc, part) => {
      const [key, val] = part.split("=");
      if (key === "t") acc[0] = val;
      if (key === "v1") acc[1] = val;
      return acc;
    }, [null, null]);

    const signedPayload = `${t}.${payload}`;
    hmac.update(signedPayload);
    const expectedSig = hmac.digest("hex");

    if (expectedSig !== v1) {
      console.error("Stripe signatur feil");
      return res.status(400).send("Ugyldig signatur");
    }

    event = JSON.parse(payload);
  } catch (err) {
    console.error("Webhook feil:", err);
    return res.status(400).send(`Webhook feil: ${err.message}`);
  }

  // Håndter checkout.session.completed
  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const email = session.customer_details?.email || session.customer_email;
    const priceId = session.line_items?.data?.[0]?.price?.id;

    if (!email) {
      console.error("Ingen e-post i session");
      return res.status(200).send("OK");
    }

    // Bestem plan basert på beløp eller price ID
    const amount = session.amount_total;
    let plan = "premium";
    if (amount >= 8900) plan = "elite"; // 89kr = 8900 øre

    console.log(`Aktiverer ${plan} for ${email}`);

    try {
      // Finn bruker i Firebase Auth via e-post
      const userRecord = await admin.auth().getUserByEmail(email).catch(() => null);

      if (userRecord) {
        // Lagre plan i Firestore
        await db.collection("subscriptions").doc(userRecord.uid).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
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
          source: "stripe_web",
        }, { merge: true });

        console.log(`⏳ Pending ${plan} for ${email} (ikke registrert ennå)`);
      }
    } catch (err) {
      console.error("Firestore feil:", err);
    }
  }

  // Håndter customer.subscription.deleted (avmelding)
  if (event.type === "customer.subscription.deleted") {
    const subscription = event.data.object;
    const email = subscription.customer_email;

    if (email) {
      const userRecord = await admin.auth().getUserByEmail(email).catch(() => null);
      if (userRecord) {
        await db.collection("subscriptions").doc(userRecord.uid).set({
          plan: "free",
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        console.log(`❌ Abonnement kansellert for ${email}`);
      }
    }
  }

  res.status(200).send("OK");
});
