#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/widgets/dev_pipeline_panel.dart"
LATEST_BAK="$(ls -1t lib/widgets/dev_pipeline_panel.dart.bak* 2>/dev/null | head -n 1 || true)"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }

if [[ -z "$LATEST_BAK" ]]; then
  echo "❌ Fant ingen backup for $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_874_before_restore.$(date +%s)"
cp "$LATEST_BAK" "$TARGET"

echo "✅ Gjenopprettet fra: $LATEST_BAK"
echo

echo "== Sjekker etter merge-markers =="
if grep -nE '^(<<<<<<<|=======|>>>>>>>)' "$TARGET"; then
  echo "❌ Merge markers finnes fortsatt i fila"
  exit 1
else
  echo "✅ Ingen merge markers funnet"
fi

echo
flutter analyze
echo "✅ 874 ferdig"
