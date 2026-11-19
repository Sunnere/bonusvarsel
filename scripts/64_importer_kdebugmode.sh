# 64: Legger til import av kDebugMode i de tre filene som bruker den etter skript 63.
# Feilen: Undefined name 'kDebugMode' (material.dart eksporterer den ikke i denne Flutter-versjonen).
# Legger til: import 'package:flutter/foundation.dart' show kDebugMode;
# Kjør fra Terminal:
#   bash ~/bonusvarsel/scripts/64_importer_kdebugmode.sh
# Test-miljø: BV_REPO=/sti/til/kopi bash scripts/64_importer_kdebugmode.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
cd "$REPO"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/64_${TS}"
mkdir -p "$BACKUP"

python3 - "$BACKUP" <<'PYEOF'
import sys, os, shutil
backup = sys.argv[1]

FILES = [
    "lib/pages/bonusvarsel_dev_hub_page.dart",
    "lib/pages/bonusvarsel_home_api_page.dart",
    "lib/pages/settings_page.dart",
]
ANCHOR = "import 'package:flutter/material.dart';\n"
NEW = "import 'package:flutter/foundation.dart' show kDebugMode;\n"

# Pass 1: valider og bygg nytt innhold
plans = {}
for path in FILES:
    if not os.path.isfile(path):
        raise SystemExit("FEIL: finner ikke %s. Ingen filer er endret." % path)
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    if "package:flutter/foundation.dart" in src:
        print("Har allerede foundation-import: " + path)
        continue
    if not src.count(ANCHOR) == 1:
        raise SystemExit("FEIL: fant ikke materialimporten nøyaktig én gang i %s. Ingen filer er endret." % path)
    plans[path] = src.replace(ANCHOR, ANCHOR + NEW, 1)

# Pass 2: backup og skriv
for path, src in plans.items():
    dest = os.path.join(backup, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(path, dest)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(src)
    print("Endret: " + path)
if not plans:
    print("Ingenting å gjøre.")
PYEOF

echo ""
echo "Kontroll (kjøres av deg):"
echo "  cd $REPO && flutter analyze --no-pub 2>&1 | grep -E \"error|kDebugMode\""
echo "  Forventet: ingen error-linjer"
