#!/usr/bin/env bash
# Skript 28: fjerner "ikke offisielt bekreftet"-disclaimeren fra alle Trippel Trumf-varsler (hoved + testrute).
# Fjerner også "kvelden før" i testteksten, siden varselet nå går søndag og onsdag.
set -euo pipefail
cd "$(dirname "$0")/.."
FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Finner ikke $FILE (kjør fra repo-roten)"; exit 1; }
if ! grep -q "Datoen er ikke offisielt bekreftet" "$FILE"; then
  echo "✅ Disclaimeren finnes ikke lenger – ingenting å gjøre."; exit 0
fi
mkdir -p .script_backups
BK=".script_backups/server.js.$(date +%Y%m%d_%H%M%S).bak"
cp "$FILE" "$BK" && echo "💾 Backup: $BK"

python3 - "$FILE" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()

D = "NB: Datoen er ikke offisielt bekreftet av Trumf ennå"
reps = [
  ("\\n\\n<i>NB: Datoen er ikke offisielt bekreftet av Trumf ennå - sjekk Trumf-appen for siste nytt.</i>", ""),
  ('<p style="color:#94A3B8;font-size:12px;">NB: Datoen er ikke offisielt bekreftet av Trumf ennå - sjekk Trumf-appen for siste nytt.</p>', ""),
  ("<i>NB: Datoen er ikke offisielt bekreftet av Trumf ennå - sjekk Trumf-appen for siste nytt.\\n(Dette er en manuell test - den ekte varslingen skjer fortsatt automatisk kvelden før.)</i>",
   "<i>(Dette er en manuell test - den ekte varslingen skjer fortsatt automatisk.)</i>"),
  ('<p style="color:#94A3B8;font-size:12px;">NB: Datoen er ikke offisielt bekreftet av Trumf ennå.<br>(Dette er en manuell test - den ekte varslingen skjer fortsatt automatisk kvelden før.)</p>',
   '<p style="color:#94A3B8;font-size:12px;">(Dette er en manuell test - den ekte varslingen skjer fortsatt automatisk.)</p>'),
]
for o, n in reps:
    c = s.count(o)
    if c != 1:
        print(f"❌ Fant {c} treff (forventet 1) for:\n{o[:100]}"); sys.exit(1)
    s = s.replace(o, n)

if D in s:
    print("❌ Disclaimer-tekst gjenstår etter fjerning"); sys.exit(1)
open(p, 'w', encoding='utf-8').write(s)
print("✅ Disclaimer fjernet fra alle 4 varianter")
PY

node --check "$FILE" && echo "✅ node --check OK"
echo "➡️  Neste: git add api/server.js scripts/28_fjern_trippel_trumf_disclaimer.sh && git commit -m 'chore: fjern usikkerhets-disclaimer fra Trippel Trumf-varsel' && git push"
