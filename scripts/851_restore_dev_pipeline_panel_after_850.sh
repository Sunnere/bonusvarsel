#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/widgets/dev_pipeline_panel.dart"
LATEST_BAK="$(ls -1t lib/widgets/dev_pipeline_panel.dart.bak_850.* 2>/dev/null | head -n 1 || true)"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }

if [[ -z "$LATEST_BAK" ]]; then
  echo "❌ Fant ingen backup fra 850: lib/widgets/dev_pipeline_panel.dart.bak_850.*"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_851_before_restore.$(date +%s)"
cp "$LATEST_BAK" "$TARGET"

echo "✅ Gjenopprettet $TARGET fra $LATEST_BAK"
echo
grep -n "businessScore\|Selected for dispatch\|Activated notifications" "$TARGET" || true
echo
flutter analyze
echo "✅ 851 ferdig"
