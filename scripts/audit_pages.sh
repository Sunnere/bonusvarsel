#!/bin/bash
echo "=== travel_page.dart ==="
cat lib/pages/travel_page.dart

echo ""
echo "=== cards_page.dart ==="
cat lib/pages/cards_page.dart

echo ""
echo "=== bonusvarsel_alerts_page.dart ==="
cat lib/pages/bonusvarsel_alerts_page.dart

echo ""
echo "=== user_state.dart ==="
cat lib/services/user_state.dart

echo ""
echo "=== notification polling (main.dart) ==="
grep -A 20 "NotificationPolling" lib/main.dart
