#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/services/api_service.dart"

LATEST_BAK="$(ls -1t lib/services/api_service.dart.bak_818.* 2>/dev/null | head -n 1 || true)"

if [[ -z "${LATEST_BAK}" ]]; then
  echo "❌ Fant ingen backup fra 818 (api_service.dart.bak_818.*)"
  exit 1
fi

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }

cp "$TARGET" "$TARGET.bak_revert_818.$(date +%s)"
cp "$LATEST_BAK" "$TARGET"

echo "✅ Gjenopprettet $TARGET fra $LATEST_BAK"
echo
echo "=== Verifiser nøkkelmetoder ==="
grep -n "getHealth\|simulateCampaignPipeline\|seedDevOffer\|getPushDispatchPreview\|getActivatedNotifications" "$TARGET" || true
echo
flutter analyze
echo "✅ 818-revert ferdig"
