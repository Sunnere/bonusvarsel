#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/services/api_service.dart"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }

cp "$TARGET" "$TARGET.bak_808_before_restore.$(date +%s)"
echo "✅ Backup laget av nåværende fil"

try_backup() {
  local src="$1"
  echo
  echo "== Tester restore fra: $src =="

  cp "$src" "$TARGET"

  if flutter analyze "$TARGET"; then
    echo "✅ Frisk restore funnet: $src"
    return 0
  fi

  echo "❌ Ikke frisk: $src"
  return 1
}

# 1) prøv de opprinnelige backupene først
for src in \
  "lib/services/api_service.dart.bak.1774036607" \
  "lib/services/api_service.dart.bak.1774036076" \
  "lib/services/api_service.dart.bak.1774035894" \
  "lib/services/api_service.dart.bak.1774035137"
do
  [[ -f "$src" ]] || continue
  try_backup "$src" && exit 0
done

# 2) hvis alle backupene er skadet, gå tilbake til git HEAD
echo
echo "== Prøver git HEAD =="
git restore --source=HEAD -- "$TARGET"

if flutter analyze "$TARGET"; then
  echo "✅ Gjenopprettet fra git HEAD"
  exit 0
fi

echo "❌ Hverken backupene eller git HEAD ga en frisk api_service.dart"
exit 1
