#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/widgets/dev_pipeline_panel.dart"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }

GOOD_BAK="$(
  ls -1t \
    lib/widgets/dev_pipeline_panel.dart.bak_868.* \
    lib/widgets/dev_pipeline_panel.dart.bak_864.* \
    lib/widgets/dev_pipeline_panel.dart.bak_863.* \
    lib/widgets/dev_pipeline_panel.dart.bak_862.* \
    lib/widgets/dev_pipeline_panel.dart.bak_861.* \
    2>/dev/null | head -n 1 || true
)"

if [[ -z "$GOOD_BAK" ]]; then
  echo "❌ Fant ingen kjent god backup (868/864/863/862/861)"
  echo "Kjør: ls -1t lib/widgets/dev_pipeline_panel.dart.bak* | head -n 30"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_875_before_restore.$(date +%s)"
cp "$GOOD_BAK" "$TARGET"

echo "✅ Gjenopprettet fra kjent god backup: $GOOD_BAK"
echo

echo "== Sjekker etter merge-markers =="
if grep -nE '^(<<<<<<<|=======|>>>>>>>)' "$TARGET"; then
  echo "❌ Merge markers finnes fortsatt"
  exit 1
else
  echo "✅ Ingen merge markers"
fi

echo
echo "== Flutter analyze =="
flutter analyze
echo "✅ 875 ferdig"
