#!/usr/bin/env bash
# 21_telegram_log.sh — logger vellykkede Telegram-utsendinger i Bonusvarsel-backenden
# og legger til GET /v1/dev/telegram-log (låst med x-admin-key). Kjør fra repo-roten:
#   bash scripts/21_telegram_log.sh
set -euo pipefail

if [ ! -f "api/server.js" ]; then
  echo "FEIL: kjør fra repo-roten til bonusvarsel (der api/server.js ligger)." >&2
  exit 1
fi

cp api/server.js api/server.js.bak_21
cat > scripts/.patch_21_telegram_log.py <<'ROY_EOF_PATCH'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
if 'TG_LOG_V1' in s:
    print('telegram-logg finnes allerede, hopper over'); sys.exit(0)

old_send = "    if (!data.ok) console.error('Telegram API avviste meldingen:', data);\n    return data.ok;"
assert s.count(old_send) == 1, 'fant ikke sendTelegram-ankeret'
new_send = (
"    if (!data.ok) console.error('Telegram API avviste meldingen:', data);\n"
"    if (data.ok) tgLogAdd({ chatId: String(chatId), text: String(message).slice(0, 2000), messageId: data.result && data.result.message_id });\n"
"    return data.ok;"
)
s = s.replace(old_send, new_send, 1)

anchor = "// ── Telegram sending ─────────────────────────────────────────────────────────"
assert s.count(anchor) == 1, 'fant ikke Telegram-seksjonen'
log_block = (
"// TG_LOG_V1: logger siste vellykkede Telegram-utsendinger (minne, siste 200). Leses av ATLAS-koordinatoren.\n"
"const TG_LOG = [];\n"
"function tgLogAdd(entry) {\n"
"  TG_LOG.push({ ...entry, sentAt: new Date().toISOString() });\n"
"  if (TG_LOG.length > 200) TG_LOG.splice(0, TG_LOG.length - 200);\n"
"}\n\n"
+ anchor
)
s = s.replace(anchor, log_block, 1)

# Endepunkt under /v1/dev er allerede låst med x-admin-key (DEV_GUARD_V1).
route_anchor = 'app.post("/v1/push/send-test", express.json(), async (req, res) => {'
assert s.count(route_anchor) == 1, 'fant ikke send-test-ruten'
route = (
"// TG_LOG_V1: GET /v1/dev/telegram-log?since=<ISO> — krever x-admin-key (devGuard).\n"
"app.get('/v1/dev/telegram-log', (req, res) => {\n"
"  const since = req.query.since ? Date.parse(req.query.since) : 0;\n"
"  const items = TG_LOG.filter((e) => Date.parse(e.sentAt) > (Number.isFinite(since) ? since : 0));\n"
"  res.json({ ok: true, count: items.length, items });\n"
"});\n\n"
+ route_anchor
)
s = s.replace(route_anchor, route, 1)
open(p, 'w', encoding='utf-8').write(s)
print('telegram-logg lagt til')
ROY_EOF_PATCH
python3 scripts/.patch_21_telegram_log.py api/server.js
rm -f scripts/.patch_21_telegram_log.py
node --check api/server.js
echo "OK: telegram-logg installert i api/server.js (backup: api/server.js.bak_21)."
echo "Neste: git add api/server.js && git commit -m 'Logg Telegram-utsendinger + /v1/dev/telegram-log' && git push origin local-stable-baseline"
