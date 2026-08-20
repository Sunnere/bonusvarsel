import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const COLLECTION = 'userEntitlements';
let db = null;
let mode = 'memory';
const memoryFallback = new Map();

function normalizePrivateKey(key) {
  if (!key) return key;
  return key.includes('\\n') ? key.replace(/\\n/g, '\n') : key;
}

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

export function init() {
  if (getApps().length > 0) {
    db = getFirestore();
    mode = 'firestore';
    return { mode };
  }
  try {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!raw) {
      console.warn('[entitlementStore] FIREBASE_SERVICE_ACCOUNT mangler, faller tilbake til memory-mode');
      mode = 'memory';
      return { mode };
    }
    const serviceAccount = JSON.parse(raw);
    serviceAccount.private_key = normalizePrivateKey(serviceAccount.private_key);
    initializeApp({ credential: cert(serviceAccount) });
    db = getFirestore();
    mode = 'firestore';
    console.log('[entitlementStore] Initialisert i firestore-mode');
  } catch (err) {
    console.error('[entitlementStore] Init feilet, faller tilbake til memory-mode:', err.message);
    mode = 'memory';
  }
  return { mode };
}

export async function getEntitlement(email) {
  const key = normalizeEmail(email);
  if (!key) return { tier: 'free', source: null };
  if (mode === 'memory') return memoryFallback.get(key) || { tier: 'free', source: null };
  const doc = await db.collection(COLLECTION).doc(key).get();
  if (!doc.exists) return { tier: 'free', source: null };
  return doc.data();
}

export async function setEntitlement(email, data) {
  const key = normalizeEmail(email);
  if (!key) throw new Error('email er påkrevd');
  const payload = { tier: 'free', source: null, ...data, email: key };
  if (mode === 'memory') {
    memoryFallback.set(key, payload);
    return payload;
  }
  await db.collection(COLLECTION).doc(key).set(
    { ...payload, updatedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
  return payload;
}

export function getMode() { return mode; }
