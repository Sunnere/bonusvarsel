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
if grep -q "STRIPE_WEBHOOK_FIX_V1" "$TARGET"; then
  echo "✅ Allerede patchet — hopper over."
  exit 0
fi

echo "=== 2) Backup ==="
mkdir -p "$BACKUP_DIR"
cp "$TARGET" "$BACKUP_DIR/index.js.$STAMP.bak"
echo "✅ Backup: $BACKUP_DIR/index.js.$STAMP.bak"

echo "=== 3) Patcher functions/index.js ==="
node - << 'NODE_EOF'
const fs = require("fs");
const file = "functions/index.js";
let src = fs.readFileSync(file, "utf8");

function replaceOnce(label, oldStr, newStr) {
  const count = src.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ Forventet nøyaktig 1 treff for "${label}", fant ${count}`);
    process.exit(1);
  }
  src = src.replace(oldStr, () => newStr);
  console.log(`✅ ${label}`);
}

replaceOnce(
  "invoice.paid lagrer stripeCustomerId",
  `      await db.collection("subscriptions").doc(userRecord.uid).set({
        plan,
        email,
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(\`✅ \${plan} aktivert for \${email}\`);
      return res.status(200).send("OK");`,
  `      await db.collection("subscriptions").doc(userRecord.uid).set({
        plan,
        email,
        source: "stripe_web",
        stripeCustomerId: invoice.customer || null,
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log(\`✅ \${plan} aktivert for \${email}\`);
      return res.status(200).send("OK");`
);

replaceOnce(
  "checkout.session.completed deklarerer description",
  `    const priceId = session.line_items?.data?.[0]?.price?.id;

    if (!email) {
      console.error("Ingen e-post i session");
      return res.status(200).send("OK");
    }

    // Bestem plan basert på beløp eller price ID
    const amount = session.amount_total;
    let plan = "premium";
    if (amount >= 8900 || description?.toLowerCase().includes('elite')) plan = "elite";`,
  `    const priceId = session.line_items?.data?.[0]?.price?.id;
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
    if (amount >= 8900 || description.toLowerCase().includes('elite')) plan = "elite";`
);

replaceOnce(
  "checkout.session.completed lagrer stripeCustomerId (registrert bruker)",
  `        await db.collection("subscriptions").doc(userRecord.uid).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          source: "stripe_web",
        }, { merge: true });`,
  `        await db.collection("subscriptions").doc(userRecord.uid).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          stripeCustomerId: session.customer || null,
          source: "stripe_web",
        }, { merge: true });`
);

replaceOnce(
  "checkout.session.completed lagrer stripeCustomerId (pending)",
  `        await db.collection("pending_subscriptions").doc(email.toLowerCase()).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          source: "stripe_web",
        }, { merge: true });`,
  `        await db.collection("pending_subscriptions").doc(email.toLowerCase()).set({
          plan,
          email,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          stripeCustomerId: session.customer || null,
          source: "stripe_web",
        }, { merge: true });`
);

replaceOnce(
  "customer.subscription.deleted slår opp på stripeCustomerId",
  `  // Håndter customer.subscription.deleted (avmelding)
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
        console.log(\`❌ Abonnement kansellert for \${email}\`);
      }
    }
  }`,
  `  // Håndter customer.subscription.deleted (avmelding)
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
        console.error(\`[stripeWebhook] Fant ikke bruker for kansellert abonnement, customerId=\${customerId}\`);
      } else {
        const subRef = db.collection("subscriptions").doc(uid);
        const existingSnap = await subRef.get();
        const existing = existingSnap.exists ? existingSnap.data() : null;
        const playStillActive =
          existing &&
          existing.source === "google_play" &&
          existing.playExpiryTime &&
          existing.playExpiryTime.toMillis() > Date.now();

        if (playStillActive) {
          console.log(\`[stripeWebhook] Stripe kansellert for uid \${uid}, men aktivt Google Play-abonnement beholdes\`);
        } else {
          await subRef.set({
            plan: "free",
            source: "stripe_web",
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          console.log(\`❌ Abonnement kansellert for uid \${uid} (customer \${customerId})\`);
        }
      }
    } catch (err) {
      console.error("Feil ved kansellering:", err);
    }
  }`
);

fs.writeFileSync(file, src);
console.log("✅ Alle patcher påført");
NODE_EOF

echo "=== 4) Syntakssjekk ==="
if node --check "$TARGET"; then
  echo "✅ Syntaks OK"
else
  echo "❌ Syntaksfeil — gjenoppretter backup"
  cp "$BACKUP_DIR/index.js.$STAMP.bak" "$TARGET"
  exit 1
fi

echo ""
echo "=== Ferdig ==="
echo "Neste: firebase deploy --only functions:stripeWebhook"
echo ""
echo "⚠️  Eksisterende brukere som allerede har en aktiv Stripe-plan i"
echo "    Firestore MANGLER stripeCustomerId (satt før denne patchen)."
echo "    Avmelding for DEM vil fortsatt ikke nedgradere automatisk før de"
echo "    får en ny invoice.paid/checkout.session.completed-hendelse, eller"
echo "    til stripeCustomerId er backfylt manuelt. Nye kjøp/fornyelser er OK."
