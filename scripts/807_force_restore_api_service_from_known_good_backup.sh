#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/services/api_service.dart"
BACKUP="lib/services/api_service.dart.bak.1774036607"

[[ -f "$TARGET" ]] || { echo "❌ Fant ikke $TARGET"; exit 1; }
[[ -f "$BACKUP" ]] || { echo "❌ Fant ikke $BACKUP"; exit 1; }

cp "$TARGET" "$TARGET.bak_807_before_force_restore.$(date +%s)"
cp "$BACKUP" "$TARGET"

echo "✅ Gjenopprettet $TARGET fra $BACKUP"
echo
echo "=== Sjekk nøkkelmetoder ==="
grep -n "getActivatedNotifications\|sendTestPush\|clearPushQueue\|seedDevOffer\|resetDevState\|getPushDispatchPreview\|simulateCampaignPipeline" "$TARGET" || true
echo
flutter analyze
echo "✅ 807 ferdig"
