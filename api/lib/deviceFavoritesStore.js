// api/lib/deviceFavoritesStore.js
//
// Write-through Firestore-cache for deviceFavorites.
// deviceFavorites-objektet i server.js beholdes uendret (samme form:
// { trumf, sas, email, telegram, tier, updatedAt } per deviceId) - denne
// modulen laster det inn fra Firestore ved oppstart og persisterer hver
// skriving, slik at favoritter overlever redeploy.
//
// Følger samme init-mønster som sentKeysStore.js: firebase-admin v14
// modulær API, automatisk normalisering av private_key.

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const COLLECTION = 'deviceFavorites';

let db = null;
let mode = 'memory';

function normalizePrivateKey(key) {
  if (!key) return key;
  return key.includes('\\n') ? key.replace(/\\n/g, '\n') : key;
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
      console.warn('[deviceFavoritesStore] FIREBASE_SERVICE_ACCOUNT mangler, faller tilbake til memory-mode');
      mode = 'memory';
      return { mode };
    }

    const serviceAccount = JSON.parse(raw);
    serviceAccount.private_key = normalizePrivateKey(serviceAccount.private_key);

    initializeApp({ credential: cert(serviceAccount) });
    db = getFirestore();
    mode = 'firestore';
    console.log('[deviceFavoritesStore] Initialisert i firestore-mode');
  } catch (err) {
    console.error('[deviceFavoritesStore] Init feilet, faller tilbake til memory-mode:', err.message);
    mode = 'memory';
  }

  return { mode };
}

export async function loadAll() {
  if (mode === 'memory') return {};

  try {
    const snapshot = await db.collection(COLLECTION).get();
    const result = {};
    snapshot.forEach((doc) => {
      result[doc.id] = doc.data();
    });
    return result;
  } catch (err) {
    console.error('[deviceFavoritesStore] loadAll feilet:', err.message);
    return {};
  }
}

export async function persist(deviceId, favs) {
  if (mode === 'memory') return;

  try {
    await db.collection(COLLECTION).doc(deviceId).set(favs, { merge: false });
  } catch (err) {
    console.error(`[deviceFavoritesStore] Kunne ikke persistere ${deviceId}:`, err.message);
  }
}

export function getMode() {
  return mode;
}
