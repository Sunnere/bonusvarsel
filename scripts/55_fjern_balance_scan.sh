# 55: Fjerner skanneflyten (readBalanceScreenshot). Beholder importflyten (importBalance).
# Bruk: bash scripts/55_fjern_balance_scan.sh
# Test-miljø: BV_REPO=/sti/til/kopi bash scripts/55_fjern_balance_scan.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
cd "$REPO"

FILES_TO_DELETE=(
  "lib/services/balance_scan_service.dart"
  "functions/balance_scan.js"
  "functions/tests/balance_scan.test.js"
)

for f in "${FILES_TO_DELETE[@]}" "functions/index.js" "lib/pages/travel_page.dart"; do
  if [ -f "$f" ]; then
    :
  else
    echo "FEIL: finner ikke $f i $REPO"
    exit 1
  fi
done

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/55_${TS}"
mkdir -p "$BACKUP"
for f in "${FILES_TO_DELETE[@]}" "functions/index.js" "lib/pages/travel_page.dart"; do
  mkdir -p "$BACKUP/$(dirname "$f")"
  cp "$f" "$BACKUP/$f"
done
echo "Backup: $REPO/$BACKUP"

for f in "${FILES_TO_DELETE[@]}"; do
  rm -f "$f"
  echo "Slettet: $f"
done

# 1) Fjern eksporten og kommentaren over den i functions/index.js
python3 - <<'PYEOF'
import re
p = "functions/index.js"
src = open(p, encoding="utf-8").read()
new, n1 = re.subn(
    r"// Les saldo fra skjermbilde \(Premium/Elite\)\n"
    r"exports\.readBalanceScreenshot = require\(\"\./balance_scan\"\)\.readBalanceScreenshot;\n\n?",
    "",
    src,
)
new, n2 = re.subn(
    r"exports\.readBalanceScreenshot = require\(\"\./balance_scan\"\)\.readBalanceScreenshot;\n\n?",
    "",
    new,
)
if n1 + n2 == 0:
    raise SystemExit("FEIL: fant ikke readBalanceScreenshot-eksporten i functions/index.js")
open(p, "w", encoding="utf-8").write(new)
print("index.js: eksport fjernet (treff: %d)" % (n1 + n2))
PYEOF

# 2) Fjern importen av den slettede tjenesten i travel_page.dart
python3 - <<'PYEOF'
p = "lib/pages/travel_page.dart"
src = open(p, encoding="utf-8").read()
line = "import '../services/balance_scan_service.dart';\n"
if line not in src:
    raise SystemExit("FEIL: fant ikke importlinjen i travel_page.dart")
open(p, "w", encoding="utf-8").write(src.replace(line, "", 1))
print("travel_page.dart: import fjernet")
PYEOF

# 3) Kontroller at ingenting peker til skanneflyten lenger
LEFT="$(grep -rn -E "readBalanceScreenshot|balance_scan|BalanceScanService|ScanFinding|BalanceScanException" lib functions --include=*.dart --include=*.js --include=*.json 2>/dev/null | grep -v node_modules | grep -v "\.bak" || true)"
if [ -n "$LEFT" ]; then
  echo "ADVARSEL: fortsatt referanser:"
  echo "$LEFT"
  exit 1
fi
echo "Ingen referanser igjen i lib/ eller functions/"

# 4) Syntakssjekk av JavaScript
node --check functions/index.js
echo "node --check: OK"

echo ""
echo "Neste steg (kjøres av deg):"
echo "  cd $REPO && flutter analyze"
echo "  firebase functions:delete readBalanceScreenshot --region us-central1"
echo "  git add -A lib functions && git commit -m 'Fjern skanneflyten (readBalanceScreenshot)'"
