#!/usr/bin/env bash
set -euo pipefail

echo "==> 778_restore_last_working_travel_page_backup"

ROOT="${PWD}"
TARGET="lib/pages/travel_page.dart"

if [[ ! -f "$TARGET" ]]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

mapfile_compat() {
  python3 - <<'PY'
from pathlib import Path
files = sorted(Path("lib/pages").glob("travel_page.dart.bak_*"), key=lambda p: p.stat().st_mtime, reverse=True)
for f in files:
    print(f)
PY
}

BACKUPS="$(mapfile_compat)"

if [[ -z "${BACKUPS}" ]]; then
  echo "❌ Fant ingen backups for travel_page.dart"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BROKEN_BAK="${TARGET}.bak_${STAMP}_778_before_restore_attempt"
cp "$TARGET" "$BROKEN_BAK"
echo "Backup av nåværende ødelagte fil: $BROKEN_BAK"

FOUND=""
TMP_OUT="/tmp/bonusvarsel_travel_restore_check.txt"

while IFS= read -r candidate; do
  [[ -z "$candidate" ]] && continue
  echo
  echo "Tester backup: $candidate"
  cp "$candidate" "$TARGET"

  if flutter analyze lib/pages/travel_page.dart >"$TMP_OUT" 2>&1; then
    FOUND="$candidate"
    echo "✅ Denne backupen analyserer uten feil: $candidate"
    break
  else
    echo "❌ Ikke gyldig:"
    tail -20 "$TMP_OUT" || true
  fi
done <<< "$BACKUPS"

if [[ -z "$FOUND" ]]; then
  echo
  echo "❌ Fant ingen backup som analyserer grønt."
  echo "Gjenoppretter original ødelagt fil så ingenting går tapt."
  cp "$BROKEN_BAK" "$TARGET"
  exit 1
fi

echo
echo "✅ Gjenopprettet fra:"
echo "   $FOUND"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
