#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/pages/bonusvarsel_dev_hub_page.dart"
LATEST_BAK="$(ls -1t lib/pages/bonusvarsel_dev_hub_page.dart.bak_819.* 2>/dev/null | head -n 1 || true)"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }

if [[ -z "$LATEST_BAK" ]]; then
  echo "❌ Fant ingen backup fra 819: lib/pages/bonusvarsel_dev_hub_page.dart.bak_819.*"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_820_before_restore.$(date +%s)"
cp "$LATEST_BAK" "$TARGET"

echo "✅ Gjenopprettet $TARGET fra $LATEST_BAK"
echo
echo "=== Verifiser nøkkelting ==="
grep -n "_quickActionsCard\|_queueActionsCard\|_alertSimulationCard\|_decisionInsightCard\|DevPipelinePanel" "$TARGET" || true
echo
flutter analyze
echo "✅ 820 ferdig"
