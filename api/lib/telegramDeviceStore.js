// lib/telegramDeviceStore.js (ESM, firebase-admin v13+/v14 modulært API)
// Persistent lagring av kobling device_id -> Telegram chat_id.
// Dette er den ROBUSTE koblingsmetoden: brukeren trykker en lenke i appen
// (https://t.me/bonusvarsel_varsel_bot?start=<deviceId>), Telegram sender
// automatisk "/start <deviceId>" til boten - vi kobler chat_id direkte til
// enheten, helt uavhengig av om brukeren har et Telegram-brukernavn eller ikke.
// Faller tilbake til ren minne-modus hvis FIREBASE_SERVICE_ACCOUNT mangler.

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const COLLECTION = 'telegramDeviceLinks';

let db = null;
let mode = 'memory';
const memory = new Map();

export function init() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    console.log('[telegramDeviceStore] FIREBASE_SERVICE_ACCOUNT mangler – kjører i minne-modus (nullstilles ved redeploy)');
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
    console.log('[telegramDeviceStore] Firestore aktivert (prosjekt: ' + creds.project_id + ')');
  } catch (err) {
    console.error('[telegramDeviceStore] Klarte ikke å initialisere Firestore, faller tilbake til minne:', err.message);
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
    console.log(`[telegramDeviceStore] Lastet ${snap.size} eksisterende koblinger fra Firestore`);
  } catch (err) {
    console.error('[telegramDeviceStore] warmUp feilet:', err.message);
  }
}

export function get(deviceId) {
  if (!deviceId) return null;
  return memory.get(String(deviceId).trim()) || null;
}

export async function set(deviceId, chatId) {
  const key = String(deviceId).trim();
  memory.set(key, chatId);
  if (mode !== 'firestore') return;
  try {
    await db.collection(COLLECTION).doc(key).set({
      deviceId: key,
      chatId,
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error('[telegramDeviceStore] Klarte ikke å lagre kobling i Firestore:', err.message);
  }
}

export function status() {
  return { mode, linkedDevices: memory.size };
}
