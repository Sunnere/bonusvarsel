#!/bin/zsh
set -e
cd /Users/sunnerehelse/bonusvarsel/api

echo "==> Skriver ESM-versjon av lib/sentKeysStore.js (overskriver CommonJS fra script 31)..."
mkdir -p lib
cat > lib/sentKeysStore.js << 'EOF'
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
EOF

echo "==> Skriver patch-script..."
cat > patch-server.mjs << 'EOF'
// patch-server.mjs – gjør presise endringer i server.js for sentKeysStore
import fs from 'fs';

const FILE = 'server.js';
let src = fs.readFileSync(FILE, 'utf8');
const orig = src;

function mustReplace(find, replace, label) {
  if (!src.includes(find)) {
    console.error(`❌ FANT IKKE (${label}):\n${find}`);
    process.exit(1);
  }
  src = src.split(find).join(replace);
  console.log(`✅ ${label}`);
}

// 1) Import av sentKeysStore etter cheerio-importen
mustReplace(
  `import * as cheerio from "cheerio";`,
  `import * as cheerio from "cheerio";
import * as sentKeysStore from './lib/sentKeysStore.js';`,
  'Import lagt til'
);

// 2) checkFavoritesAndNotify: has()/add() mot Firestore
mustReplace(
  `        if (state.sentCampaignKeys.has(key)) continue;
        newCampaigns.push(campaign);
        state.sentCampaignKeys.add(key);`,
  `        if (sentKeysStore.has(key)) continue;
        newCampaigns.push(campaign);
        await sentKeysStore.add(key);`,
  'checkFavoritesAndNotify bruker sentKeysStore'
);

// 3) /dev/reset-sent-keys nullstiller også Firestore
mustReplace(
  `app.post("/dev/reset-sent-keys", (req, res) => {
  state.sentCampaignKeys = new Set();
  res.json({ ok: true, message: "sentCampaignKeys nullstilt" });
});`,
  `app.post("/dev/reset-sent-keys", async (req, res) => {
  state.sentCampaignKeys = new Set();
  await sentKeysStore.reset();
  res.json({ ok: true, message: "sentCampaignKeys nullstilt (minne + Firestore)", store: sentKeysStore.status() });
});`,
  '/dev/reset-sent-keys nullstiller Firestore'
);

// 4) /health viser lagringsmodus
mustReplace(
  `    ok: true,
    api: "up",
    version: appVersion,
    devRoutesEnabled: enableDevRoutes,
    pipeline: buildPipelineState(),`,
  `    ok: true,
    api: "up",
    version: appVersion,
    devRoutesEnabled: enableDevRoutes,
    sentKeys: sentKeysStore.status(),
    pipeline: buildPipelineState(),`,
  '/health viser sentKeys-status'
);

// 5) Init + warmUp ved oppstart, før app.listen
mustReplace(
  `app.listen(port, () => {`,
  `sentKeysStore.init();
sentKeysStore.warmUp().catch((e) => console.error('[sentKeysStore] warmUp error:', e));

app.listen(port, () => {`,
  'init() + warmUp() ved oppstart'
);

if (src === orig) {
  console.error('❌ Ingen endringer gjort');
  process.exit(1);
}
fs.writeFileSync(FILE, src);
console.log('✅ server.js patchet');
EOF

echo "==> Sikkerhetskopi av server.js..."
cp server.js server.js.bak-script32

echo "==> Kjører patch..."
node patch-server.mjs

echo "==> Syntaks-sjekk..."
node --check server.js && echo "✅ SYNTAKS OK"

echo "==> Rydder opp patch-script..."
rm patch-server.mjs

echo ""
echo "✅ FERDIG. Neste: commit + push (se instruksjoner i chatten)."
