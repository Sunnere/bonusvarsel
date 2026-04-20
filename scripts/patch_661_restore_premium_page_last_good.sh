#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

echo "==> Ser etter premium_page backups"
ls -1 "${FILE}".bak* 2>/dev/null || {
  echo "❌ Fant ingen backups for $FILE"
  exit 1
}

# Prioritet:
# 1) backup før patch_660
# 2) backup før patch_659
# 3) backup før patch_658
# 4) backup før patch_657
CANDIDATES=(
  "${FILE}.bak_660_remove_bottom_upgrade_section"
  "${FILE}.bak_659_move_membership_above_plans_and_luxury_elite"
  "${FILE}.bak_658_plan_picker_under_floating_bar_and_luxury_shell"
  "${FILE}.bak_657_upgrade_membership_cards_brand_and_target"
  "${FILE}.bak_656_replace_supported_cards_with_membership_ads"
  "${FILE}.bak_655_add_supported_cards_section_under_plans"
  "${FILE}.bak_654_luxury_upgrade_ad_section"
  "${FILE}.bak_653_add_upgrade_ad_to_premium_page"
)

RESTORE_FROM=""
for f in "${CANDIDATES[@]}"; do
  if [ -f "$f" ]; then
    RESTORE_FROM="$f"
    break
  fi
done

if [ -z "$RESTORE_FROM" ]; then
  echo "❌ Fant ingen kjent backup å restore fra."
  exit 1
fi

cp "$RESTORE_FROM" "$FILE"
echo "✅ Gjenopprettet $FILE fra:"
echo "   $RESTORE_FROM"

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
