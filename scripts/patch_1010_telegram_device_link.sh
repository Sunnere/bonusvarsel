#!/bin/bash
set -euo pipefail

FILE="api/server.js"
STORE_FILE="api/lib/telegramDeviceStore.js"
BACKUP="${FILE}.bak_1010_telegram_device_link_$(date +%Y%m%d_%H%M%S)"

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
STOREEOF

echo "✅ Opprettet $STORE_FILE"

python3 - "$FILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

edits = []

edits.append((
    "import * as telegramLinkStore from './lib/telegramLinkStore.js';",
    "import * as telegramLinkStore from './lib/telegramLinkStore.js';\nimport * as telegramDeviceStore from './lib/telegramDeviceStore.js';"
))

edits.append((
    '''app.post("/telegram/webhook", express.json(), async (req, res) => {
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
});''',
    '''app.post("/telegram/webhook", express.json(), async (req, res) => {
  try {
    const msg = req.body && req.body.message;
    const username = msg && msg.from && msg.from.username;
    const chatId = msg && msg.chat && msg.chat.id;
    const text = (msg && msg.text) || '';
    let linked = false;

    const startMatch = text.match(/^\\/start(?:@\\w+)?\\s+(\\S+)/);
    if (startMatch && chatId) {
      const deviceId = startMatch[1];
      await telegramDeviceStore.set(deviceId, chatId);
      console.log(`[telegram/webhook] Koblet enhet ${deviceId} -> chat_id ${chatId}`);
      linked = true;
    }

    if (username && chatId) {
      await telegramLinkStore.set(username, chatId);
      console.log(`[telegram/webhook] Koblet @${username} -> chat_id ${chatId}`);
      linked = true;
    }

    if (linked) {
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
    '''      const tgChatId = favs.telegram ? telegramLinkStore.get(favs.telegram) : null;
      if (favs.telegram && !tgChatId) {
        console.log(`[CHECKFAV] ${deviceId}: @${favs.telegram} har ikke startet @bonusvarsel_bot ennå - kan ikke sende Telegram`);
      }
      const tgOk = tgChatId ? await sendTelegram(msg, tgChatId) : false;''',
    '''      const tgChatId = telegramDeviceStore.get(deviceId) || (favs.telegram ? telegramLinkStore.get(favs.telegram) : null);
      if (!tgChatId && favs.telegram) {
        console.log(`[CHECKFAV] ${deviceId}: @${favs.telegram} har ikke startet @bonusvarsel_varsel_bot ennå - kan ikke sende Telegram`);
      }
      const tgOk = tgChatId ? await sendTelegram(msg, tgChatId) : false;'''
))

edits.append((
    "telegramLinkStore.init();\ntelegramLinkStore.warmUp().catch((e) => console.error('[telegramLinkStore] warmUp error:', e));",
    "telegramLinkStore.init();\ntelegramLinkStore.warmUp().catch((e) => console.error('[telegramLinkStore] warmUp error:', e));\ntelegramDeviceStore.init();\ntelegramDeviceStore.warmUp().catch((e) => console.error('[telegramDeviceStore] warmUp error:', e));"
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

print("✅ server.js oppdatert: robust enhets-lenke-kobling for Telegram lagt til")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  node --check $FILE"
echo "  node --check $STORE_FILE"
