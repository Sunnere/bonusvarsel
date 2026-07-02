// lib/sentKeysStore.js (ESM)
// Persistent lagring av sentCampaignKeys i Firestore.
// Faller tilbake til ren minne-modus hvis FIREBASE_SERVICE_ACCOUNT mangler
// eller Firestore feiler – serveren skal aldri krasje pga. dette.

import admin from 'firebase-admin';

const COLLECTION = 'sentCampaignKeys';

let db = null;
let mode = 'memory'; // 'firestore' | 'memory'
const memory = new Set();

export function init() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    console.log('[sentKeysStore] FIREBASE_SERVICE_ACCOUNT mangler – kjører i minne-modus (nullstilles ved redeploy)');
    return;
  }
  try {
    const creds = JSON.parse(raw);
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(creds) });
    }
    db = admin.firestore();
    mode = 'firestore';
    console.log('[sentKeysStore] Firestore aktivert (prosjekt: ' + creds.project_id + ')');
  } catch (err) {
    console.error('[sentKeysStore] Klarte ikke å initialisere Firestore, faller tilbake til minne:', err.message);
    db = null;
    mode = 'memory';
  }
}

// Last alle nøkler inn i minne-cachen ved oppstart (rask has()-sjekk, ingen read per kampanje)
export async function warmUp() {
  if (mode !== 'firestore') return;
  try {
    const snap = await db.collection(COLLECTION).get();
    snap.forEach((doc) => memory.add(doc.id));
    console.log(`[sentKeysStore] Lastet ${snap.size} eksisterende nøkler fra Firestore`);
  } catch (err) {
    console.error('[sentKeysStore] warmUp feilet:', err.message);
  }
}

export function has(key) {
  return memory.has(safeId(key));
}

export async function add(key) {
  const id = safeId(key);
  memory.add(id);
  if (mode !== 'firestore') return;
  try {
    await db.collection(COLLECTION).doc(id).set({
      key: String(key),
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error('[sentKeysStore] Klarte ikke å lagre nøkkel i Firestore:', err.message);
  }
}

export async function reset() {
  memory.clear();
  if (mode !== 'firestore') return;
  try {
    // Slett i batcher på 400 (Firestore-grense er 500 per batch)
    let snap = await db.collection(COLLECTION).limit(400).get();
    while (!snap.empty) {
      const batch = db.batch();
      snap.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      snap = await db.collection(COLLECTION).limit(400).get();
    }
    console.log('[sentKeysStore] Alle nøkler slettet fra Firestore');
  } catch (err) {
    console.error('[sentKeysStore] reset feilet:', err.message);
  }
}

export function status() {
  return { mode, cachedKeys: memory.size };
}

// Firestore-dokument-ID tåler ikke '/'
function safeId(key) {
  return String(key).replace(/\//g, '_');
}
