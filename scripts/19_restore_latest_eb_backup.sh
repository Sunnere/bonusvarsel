#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
LATEST="$(ls -t "${FILE}.bak."* 2>/dev/null | head -n 1 || true)"

if [[ -z "${LATEST}" ]]; then
  echo "Fant ingen backup-filer: ${FILE}.bak.*"
  exit 1
fi

echo "✅ Restore fra: ${LATEST}"
cp "${LATEST}" "${FILE}"

dart format "${FILE}" || true
flutter analyze || true
