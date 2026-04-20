#!/usr/bin/env bash
set -euo pipefail

echo "==> 763_restore_travel_page_pre_750"

TARGET="lib/pages/travel_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
cp "$TARGET" "${TARGET}.bak_${STAMP}_763_before_restore"

BEST_BACKUP="$(
python3 <<'PY'
from pathlib import Path
import re

files = sorted(Path("lib/pages").glob("travel_page.dart.bak_*"), reverse=True)

best = None
for f in files:
    m = re.search(r'_(\d+)$', f.name)
    if not m:
        continue
    tag = int(m.group(1))
    if tag < 750:
        best = f
        break

print(best if best else "")
PY
)"

if [ -z "${BEST_BACKUP:-}" ]; then
  echo "❌ Fant ingen backup før 750-serien."
  echo
  echo "Kjør dette for å se backups:"
  echo "  ls -1t lib/pages/travel_page.dart.bak_* | head -40"
  exit 1
fi

echo "Bruker backup:"
echo "  $BEST_BACKUP"

cp "$BEST_BACKUP" "$TARGET"

echo
echo "✅ travel_page.dart er rullet tilbake til siste backup før 750-serien"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
