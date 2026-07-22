#!/bin/bash
set -euo pipefail

WF_DIR=".github/workflows"
MAIN_FILE="$WF_DIR/bonusvarsel-matrix.yml"

if [ ! -f "$MAIN_FILE" ]; then
  echo "❌ Fant ikke $MAIN_FILE. Kjør dette scriptet fra rot-mappen i repoet."
  exit 1
fi

BACKUP_DIR=".github/workflows_removed_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

for f in "bonusvarsel-matrix.nested.1771770241.yml" "bonusvarsel-sas.yml" "bonusvarsel.yml"; do
  if [ -f "$WF_DIR/$f" ]; then
    mv "$WF_DIR/$f" "$BACKUP_DIR/"
    echo "✅ Flyttet $f til $BACKUP_DIR/"
  else
    echo "ℹ️  $f finnes ikke (allerede fjernet?) – hopper over"
  fi
done

if [ -d "$WF_DIR/_bak_nested_1771770241" ]; then
  mv "$WF_DIR/_bak_nested_1771770241" "$BACKUP_DIR/_bak_nested_1771770241"
  echo "✅ Flyttet _bak_nested_1771770241/ til $BACKUP_DIR/"
else
  echo "ℹ️  _bak_nested_1771770241/ finnes ikke – hopper over"
fi

python3 - "$MAIN_FILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old_cron = '    - cron: "0 * * * *"\n'
new_cron = '    - cron: "0 6 * * 4"  # torsdager kl 06:00 UTC (~08:00 norsk sommertid / 07:00 vintertid)\n'

if old_cron not in src:
    print("❌ Fant ikke forventet cron-linje. Ingen endringer gjort i workflow-filen.")
    sys.exit(1)

src = src.replace(old_cron, new_cron, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ bonusvarsel-matrix.yml kjører nå torsdager kl 06:00 UTC i stedet for hver time")
PYEOF

echo
echo "Verifiser:"
echo "  cat $MAIN_FILE | grep -A2 schedule"
echo "  ls $WF_DIR"
echo
echo "NB: Filene ble FLYTTET (ikke slettet permanent) til $BACKUP_DIR/ – de forsvinner"
echo "helt fra repoet når du committer og pusher (git ser dem som slettet + git history har dem uansett)."
