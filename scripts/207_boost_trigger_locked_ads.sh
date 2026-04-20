#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p lib/services
mkdir -p lib/widgets

echo "Backup..."
cp lib/widgets/ad_slot.dart lib/widgets/ad_slot.dart.bak.$STAMP || true

# --------------------------------------------------
# SERVICE: BoostLockService
# --------------------------------------------------
cat > lib/services/boost_lock_service.dart <<'DART'
class BoostLockService {
  static bool isLocked(String placement) {
    // Definer hva som er låst
    // Juster etter behov senere
    return placement.contains('elite') || placement.contains('premium');
  }
}
DART

# --------------------------------------------------
# PATCH AdSlotCard
# --------------------------------------------------
perl -0777 -pe "
s/import '\.\.\/services\/ad_service.dart';/import '..\/services\/ad_service.dart';\nimport '..\/services\/boost_lock_service.dart';\nimport '..\/services\/paywall_trigger_service.dart';/g
" -i lib/widgets/ad_slot.dart

# --------------------------------------------------
# PATCH onTap behavior
# --------------------------------------------------
perl -0777 -pe "
s/onTap: \(\) async \{/onTap: () async {\n      final locked = BoostLockService.isLocked(widget.placement);\n      if (locked) {\n        await PaywallTriggerService.showPaywall(\n          context,\n          source: 'locked_ad',\n          title: 'Lås opp flere tilbud',\n          subtitle: 'Premium gir tilgang til flere butikker og høyere bonus.',\n        );\n        return;\n      }/g
" -i lib/widgets/ad_slot.dart

echo "Boost trigger installert"

echo
echo "Kjør nå:"
echo "flutter analyze"
echo "flutter test"
