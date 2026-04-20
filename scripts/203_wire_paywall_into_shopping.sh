#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "Finner ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak_203"

echo "Patcher $FILE..."

# 1. Legg til import hvis ikke finnes
grep -q "paywall_trigger_service.dart" "$FILE" || \
sed -i '' "1s|^|import '../services/paywall_trigger_service.dart';\n|" "$FILE"

# 2. Legg til ScrollController i State class hvis ikke finnes
grep -q "_scrollController" "$FILE" || \
sed -i '' "/class .*State extends State/ a\\
  final ScrollController _scrollController = ScrollController();
" "$FILE"

# 3. Legg til initState scroll listener hvis ikke finnes
grep -q "scroll_depth" "$FILE" || \
sed -i '' "/initState()/,/super.initState()/ s|super.initState();|super.initState();\\
\\
    _scrollController.addListener(() async {\\
      if (_scrollController.offset > 600) {\\
        final seen = await PaywallTriggerService.hasSeenScrollDepth();\\
        if (!seen && context.mounted) {\\
          await PaywallTriggerService.markScrollDepthSeen();\\
          await PaywallTriggerService.showPaywall(\\
            context,\\
            source: 'scroll_depth',\\
            title: 'Du ser mye – få mer verdi',\\
            subtitle: 'Premium gir deg høyere rate og smartere valg.',\\
          );\\
        }\\
      }\\
    });|" "$FILE"

# 4. Koble controller til ListView hvis mulig
grep -q "controller: _scrollController" "$FILE" || \
sed -i '' "s/ListView(/ListView(controller: _scrollController, /" "$FILE"

# 5. Legg inn TODO for boost trigger
grep -q "PAYWALL BOOST TRIGGER" "$FILE" || \
echo "
// ===== PAYWALL BOOST TRIGGER =====
// Finn der du har 'Boost i Premium' og legg dette i onTap:
//
// onTap: () async {
//   await PaywallTriggerService.registerLockedTap();
//   final shouldShow = await PaywallTriggerService.shouldShowAfterLockedTap();
//   if (shouldShow && context.mounted) {
//     await PaywallTriggerService.showPaywall(
//       context,
//       source: 'locked_boost_chip',
//       title: 'Få høyere poengrate',
//       subtitle: 'Premium gir deg boosts og bedre valg.',
//     );
//   }
// };
" >> "$FILE"

echo "Ferdig patch."
echo "Backup: $FILE.bak_203"
echo
echo "Kjør nå:"
echo "flutter analyze"
echo "flutter test"
