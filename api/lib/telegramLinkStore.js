// lib/telegramLinkStore.js (ESM, firebase-admin v13+/v14 modulært API)
// Persistent lagring av kobling Telegram-brukernavn -> chat_id i Firestore.
// Nødvendig fordi Telegram Bot API IKKE kan sende meldinger basert på
// brukernavn alene - kun chat_id, som vi kun får når brukeren selv har
// startet en samtale med boten (webhook fanger den opp, se /telegram/webhook).
// Faller tilbake til ren minne-modus hvis FIREBASE_SERVICE_ACCOUNT mangler.

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const COLLECTION = 'telegramLinks';

let db = null;
let mode = 'memory'; // 'firestore' | 'memory'
const memory = new Map(); // normalisert brukernavn -> chat_id

export function init() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    console.log('[telegramLinkStore] FIREBASE_SERVICE_ACCOUNT mangler – kjører i minne-modus (nullstilles ved redeploy)');
    return;
  }
  try {
    const creds = JSON.parse(raw);
    if (typeof creds.private_key === 'string' && creds.private_key.includes('\\n')) {
      creds.private_key = creds.private_key.replace(/\\n/g, '\n');
    }
    if (!getApps().length) {
      initializeApp({ credential: cert(creds) });
    }
    db = getFirestore();
    mode = 'firestore';
    console.log('[telegramLinkStore] Firestore aktivert (prosjekt: ' + creds.project_id + ')');
  } catch (err) {
    console.error('[telegramLinkStore] Klarte ikke å initialisere Firestore, faller tilbake til minne:', err.message);
    db = null;
    mode = 'memory';
  }
}

export async function warmUp() {
  if (mode !== 'firestore') return;
  try {
    const snap = await db.collection(COLLECTION).get();
    snap.forEach((doc) => {
      const data = doc.data();
      if (data && data.chatId) memory.set(doc.id, data.chatId);
    });
    console.log(`[telegramLinkStore] Lastet ${snap.size} eksisterende koblinger fra Firestore`);
  } catch (err) {
    console.error('[telegramLinkStore] warmUp feilet:', err.message);
  }
}

export function get(username) {
  if (!username) return null;
  return memory.get(normalize(username)) || null;
}

export async function set(username, chatId) {
  const key = normalize(username);
  memory.set(key, chatId);
  if (mode !== 'firestore') return;
  try {
    await db.collection(COLLECTION).doc(key).set({
      username: key,
      chatId,
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error('[telegramLinkStore] Klarte ikke å lagre kobling i Firestore:', err.message);
  }
}

export function status() {
  return { mode, linkedUsers: memory.size };
}

function normalize(username) {
  return String(username).toLowerCase().replace(/^@/, '').trim();
}
