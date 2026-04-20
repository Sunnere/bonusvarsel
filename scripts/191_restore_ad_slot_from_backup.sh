#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/ad_slot.dart"

LATEST_BACKUP="$(ls -t ${FILE}.bak.* 2>/dev/null | head -n 1 || true)"

if [ -z "${LATEST_BACKUP}" ]; then
  echo "Fant ingen backup for ${FILE}"
  echo "Forventet noe som: ${FILE}.bak.YYYYMMDD-HHMMSS"
  exit 1
fi

cp "${LATEST_BACKUP}" "${FILE}"

echo "Gjenopprettet ${FILE} fra backup:"
echo "  ${LATEST_BACKUP}"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter test"
