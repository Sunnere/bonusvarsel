#!/usr/bin/env bash
# Skript 26: program-alert teller kun e-post/Telegram som FAKTISK ble sendt.
# - sendEmail() returnerer false ved avvisning (Brevo) -> telles nå som emailFailed
# - nøkkelen markeres kun som sendt hvis minst én kanal lyktes (ellers kan du prøve igjen)
set -euo pipefail
cd "$(dirname "$0")/.."
FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Finner ikke $FILE (kjør fra repo-roten)"; exit 1; }
mkdir -p .script_backups
BK=".script_backups/server.js.$(date +%Y%m%d_%H%M%S).bak"
cp "$FILE" "$BK" && echo "💾 Backup: $BK"

python3 - "$FILE" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()

old1 = "const result = { matched: 0, alreadySent: 0, telegram: 0, email: 0, errors: 0 };"
new1 = "const result = { matched: 0, alreadySent: 0, telegram: 0, telegramFailed: 0, email: 0, emailFailed: 0, errors: 0 };"

old2 = """      if (tgChatId && await sendTelegram(tgMsg, tgChatId)) result.telegram++;
      if (favs.email) { await sendEmail(favs.email, `💸 ${label}: ${title}`, html); result.email++; }
      await sentKeysStore.add(key);"""
new2 = """      let delivered = false;
      if (tgChatId) {
        if (await sendTelegram(tgMsg, tgChatId)) { result.telegram++; delivered = true; }
        else result.telegramFailed++;
      }
      if (favs.email) {
        if (await sendEmail(favs.email, `💸 ${label}: ${title}`, html)) { result.email++; delivered = true; }
        else result.emailFailed++;
      }
      // Marker som sendt kun hvis minst én kanal lyktes – ellers kan samme varsel sendes på nytt
      if (delivered) await sentKeysStore.add(key);
      else result.errors++;"""

for o in (old1, old2):
    if s.count(o) != 1:
        print("❌ Fant ikke eksakt ett treff for:\n" + o[:80]); sys.exit(1)
s = s.replace(old1, new1).replace(old2, new2)
open(p, 'w', encoding='utf-8').write(s)
print("✅ Patchet", p)
PY

node --check "$FILE" && echo "✅ node --check OK"
echo "➡️  Deploy: git add api/server.js && git commit -m 'fix: program-alert teller kun leverte varsler' && git push"
