// scripts/apply_check_subscription_debug.mjs
//
// Legger til midlertidig logging i checkSubscription for å avsløre
// hvorfor den returnerer 'free' selv om Firestore-dokumentet finnes.
//
// Kjør med: node scripts/apply_check_subscription_debug.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FILE = path.join(__dirname, '..', 'functions', 'index.js');

let content = fs.readFileSync(FILE, 'utf8');
const original = content;

if (content.includes('[DEBUG checkSubscription]')) {
  console.error('FEIL: debug-logging finnes allerede. Avbryter uten å endre noe.');
  process.exit(1);
}

const search = `exports.checkSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) return { plan: 'free' };
  
  try {
    const doc = await db.collection('subscriptions').doc(context.auth.uid).get();
    if (doc.exists) {
      return { plan: doc.data().plan || 'free' };
    }
    // Sjekk pending med e-post
    const email = context.auth.token.email;
    if (email) {
      const pending = await db.collection('pending_subscriptions')
        .doc(email.toLowerCase()).get();
      if (pending.exists) {
        return { plan: pending.data().plan || 'free' };
      }
    }
    return { plan: 'free' };
  } catch (e) {
    return { plan: 'free' };
  }
});`;

const replace = `exports.checkSubscription = functions.https.onCall(async (data, context) => {
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
});`;

const count = content.split(search).length - 1;
if (count === 0) {
  throw new Error('FEIL: fant ikke checkSubscription-funksjonen nøyaktig som forventet. Lim inn din faktiske funksjon så jeg justerer scriptet.');
}
if (count > 1) {
  throw new Error(`FEIL: fant den ${count} ganger. Avbryter.`);
}

content = content.replace(search, replace);

const backupPath = FILE + `.bak_debug.${Date.now()}`;
fs.writeFileSync(backupPath, original, 'utf8');
fs.writeFileSync(FILE, content, 'utf8');

console.log(`OK: functions/index.js oppdatert (backup: ${path.basename(backupPath)})`);
console.log('Kjør nå: cd functions && npm run deploy');
