#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/widgets/dev_pipeline_panel.dart"
LATEST_BAK="$(ls -1t lib/widgets/dev_pipeline_panel.dart.bak_845.* 2>/dev/null | head -n 1 || true)"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }

if [[ -z "$LATEST_BAK" ]]; then
  echo "❌ Fant ingen backup fra 845: lib/widgets/dev_pipeline_panel.dart.bak_845.*"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_846_before_restore.$(date +%s)"
cp "$LATEST_BAK" "$TARGET"

echo "✅ Gjenopprettet $TARGET fra $LATEST_BAK"
echo
grep -n "Selected for dispatch\|Recent campaigns\|Activated notifications" "$TARGET" || true
echo
flutter analyze
echo "✅ 846 ferdig"
