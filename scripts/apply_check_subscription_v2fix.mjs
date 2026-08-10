// scripts/apply_check_subscription_v2fix.mjs
//
// ROTÅRSAK: checkSubscription brukte v1-signaturen (data, context), men
// firebase-functions v7 kjører på v2-API-et der callable-handlere kun tar
// ETT argument: (request), med request.auth. Feil signatur gjorde at
// context.auth alltid ble null, selv for korrekt innloggede brukere.
//
// Kjør med: node scripts/apply_check_subscription_v2fix.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'functions', 'index.js');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes("require(\"firebase-functions/v2/https\")")) {
  console.error('FEIL: v2-importen finnes allerede. Sjekk manuelt om checkSubscription allerede er fikset.');
  process.exit(1);
}

function replaceOnce(content, search, replace, label) {
  const count = content.split(search).length - 1;
  if (count === 0) {
    throw new Error(`FEIL: fant ikke ankertekst for "${label}". Ingen endringer gjort.`);
  }
  if (count > 1) {
    throw new Error(`FEIL: fant ankertekst for "${label}" ${count} ganger (forventet 1). Avbryter.`);
  }
  return content.replace(search, replace);
}

content = replaceOnce(
  content,
  `const functions = require("firebase-functions");`,
  `const functions = require("firebase-functions");\nconst { onCall } = require("firebase-functions/v2/https");`,
  'import v2 onCall'
);

content = replaceOnce(
  content,
  `exports.checkSubscription = functions.https.onCall(async (data, context) => {
  console.log('[DEBUG checkSubscription] context.auth:', context.auth ? { uid: context.auth.uid, email: context.auth.token?.email } : null);

  if (!context.auth) return { plan: 'free' };

  try {
    const doc = await db.collection('subscriptions').doc(context.auth.uid).get();
    console.log('[DEBUG checkSubscription] doc.exists:', doc.exists, 'data:', doc.exists ? doc.data() : null);

    if (doc.exists) {
      return { plan: doc.data().plan || 'free' };
    }
    const email = context.auth.token.email;
    if (email) {
      const pending = await db.collection('pending_subscriptions')
        .doc(email.toLowerCase()).get();
      console.log('[DEBUG checkSubscription] pending.exists:', pending.exists);
      if (pending.exists) {
        return { plan: pending.data().plan || 'free' };
      }
    }
    return { plan: 'free' };
  } catch (e) {
    console.error('[DEBUG checkSubscription] FEIL FANGET:', e.message, e.stack);
    return { plan: 'free' };
  }
});`,
  `exports.checkSubscription = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) return { plan: 'free' };

  try {
    const doc = await db.collection('subscriptions').doc(auth.uid).get();

    if (doc.exists) {
      return { plan: doc.data().plan || 'free' };
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
});`,
  'checkSubscription v2-signatur'
);

if (content === original) {
  console.log('Ingen endringer gjort (uventet).');
  process.exit(1);
}

const backupPath = FILE + `.bak_v2fix.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: functions/index.js oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: cd functions && firebase deploy --only functions:checkSubscription');
