#!/bin/bash
set -euo pipefail

FILE="api/server.js"
STORE_FILE="api/lib/telegramLinkStore.js"
BACKUP="${FILE}.bak_1006_telegram_per_user_$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE. Kjør dette scriptet fra rot-mappen i repoet."
  exit 1
fi

if [ -f "$STORE_FILE" ]; then
  echo "❌ $STORE_FILE finnes allerede. Avbryter for å ikke overskrive noe uventet."
  exit 1
fi

cp "$FILE" "$BACKUP"

cat > "$STORE_FILE" << 'STOREEOF'
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
STOREEOF

echo "✅ Opprettet $STORE_FILE"

python3 - "$FILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

edits = []

edits.append((
    "import * as sentKeysStore from './lib/sentKeysStore.js';",
    "import * as sentKeysStore from './lib/sentKeysStore.js';\nimport * as telegramLinkStore from './lib/telegramLinkStore.js';"
))

edits.append((
    '''async function sendTelegram(message) {
  if (!TG_BOT_TOKEN || !TG_CHAT_ID) {
    console.warn('Telegram ikke konfigurert');
    return false;
  }
  try {
    const url = `https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage`;
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: TG_CHAT_ID,
        text: message,
        parse_mode: 'HTML',
      }),
    });
    const data = await r.json();
    return data.ok;
  } catch (e) {
    console.error('Telegram feil:', e);
    return false;
  }
}''',
    '''async function sendTelegram(message, chatId = TG_CHAT_ID) {
  if (!TG_BOT_TOKEN || !chatId) {
    console.warn('Telegram ikke konfigurert (mangler bot-token eller chat_id)');
    return false;
  }
  try {
    const url = `https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage`;
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: 'HTML',
      }),
    });
    const data = await r.json();
    if (!data.ok) console.error('Telegram API avviste meldingen:', data);
    return data.ok;
  } catch (e) {
    console.error('Telegram feil:', e);
    return false;
  }
}'''
))

edits.append((
    '''app.post("/v1/devices/favorites", express.json(), (req, res) => {
  const { trumf = [], sas = [], email = null } = req.body || {};
  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf, sas, email, updatedAt: new Date().toISOString() };
  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumf.length}, SAS=${sas.length}, Email=${email || 'ingen'}`);
  res.json({ ok: true, trumf: trumf.length, sas: sas.length });
});''',
    '''app.post("/v1/devices/favorites", express.json(), (req, res) => {
  const { trumf = [], sas = [], email = null, telegram = null } = req.body || {};
  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf, sas, email, telegram, updatedAt: new Date().toISOString() };
  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumf.length}, SAS=${sas.length}, Email=${email || 'ingen'}, Telegram=${telegram || 'ingen'}`);
  res.json({ ok: true, trumf: trumf.length, sas: sas.length });
});

// Telegram-webhook: fanger opp chat_id når en bruker starter/skriver til @bonusvarsel_bot,
// og kobler det til brukernavnet deres (kun slik kan vi senere sende dem private meldinger).
app.post("/telegram/webhook", express.json(), async (req, res) => {
  try {
    const msg = req.body && req.body.message;
    const username = msg && msg.from && msg.from.username;
    const chatId = msg && msg.chat && msg.chat.id;
    if (username && chatId) {
      await telegramLinkStore.set(username, chatId);
      console.log(`[telegram/webhook] Koblet @${username} -> chat_id ${chatId}`);
      await sendTelegram(
        '✅ Du er nå koblet til Bonusvarsel! Du vil motta varsler her når favorittene dine får kampanjer (eller ukens beste tilbud hvis du ikke har valgt noen).',
        chatId
      );
    }
  } catch (e) {
    console.error('[telegram/webhook] feil:', e);
  }
  res.sendStatus(200);
});'''
))

edits.append((
    "      const tgOk = await sendTelegram(msg);",
    '''      const tgChatId = favs.telegram ? telegramLinkStore.get(favs.telegram) : null;
      if (favs.telegram && !tgChatId) {
        console.log(`[CHECKFAV] ${deviceId}: @${favs.telegram} har ikke startet @bonusvarsel_bot ennå - kan ikke sende Telegram`);
      }
      const tgOk = tgChatId ? await sendTelegram(msg, tgChatId) : false;'''
))

edits.append((
    "sentKeysStore.init();\nsentKeysStore.warmUp().catch((e) => console.error('[sentKeysStore] warmUp error:', e));",
    "sentKeysStore.init();\nsentKeysStore.warmUp().catch((e) => console.error('[sentKeysStore] warmUp error:', e));\ntelegramLinkStore.init();\ntelegramLinkStore.warmUp().catch((e) => console.error('[telegramLinkStore] warmUp error:', e));"
))

missing = []
for old, new in edits:
    if old not in src:
        missing.append(old[:80])
    else:
        src = src.replace(old, new, 1)

if missing:
    print("❌ Fant ikke følgende kodeblokk(er), ingen endringer lagret:")
    for m in missing:
        print("   -", m)
    sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ server.js oppdatert: webhook lagt til, telegram lagres per enhet, meldinger sendes til riktig person")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  node --check $FILE"
echo "  node --check $STORE_FILE"
