#!/usr/bin/env bash
set -euo pipefail

MAIN="lib/main.dart"
DEV_HUB="lib/pages/bonusvarsel_dev_hub_page.dart"

[[ -f "$MAIN" ]] || { echo "❌ Fant ikke $MAIN"; exit 1; }
[[ -f "$DEV_HUB" ]] || { echo "❌ Fant ikke $DEV_HUB"; exit 1; }

cp "$MAIN" "$MAIN.bak_876.$(date +%s)"
cp "$DEV_HUB" "$DEV_HUB.bak_876.$(date +%s)"

echo "✅ Backup laget"

cat > "$MAIN" <<'DART'
import 'package:flutter/material.dart';
import 'package:bonusvarsel/config/app_env.dart';
import 'package:bonusvarsel/pages/home_page.dart';
import 'theme/app_theme.dart';
import 'package:bonusvarsel/services/api_service.dart';

void main() {
  ApiService.registerDemoDeviceOnce();
  runApp(const BonusvarselApp());
  NotificationPolling.start();
}

class BonusvarselApp extends StatelessWidget {
  const BonusvarselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      title: AppEnv.isProd ? 'Bonusvarsel' : 'Bonusvarsel (${AppEnv.appFlavor})',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
DART

GOOD_DEV_HUB="$(
  ls -1t \
    lib/pages/bonusvarsel_dev_hub_page.dart.bak_861.* \
    lib/pages/bonusvarsel_dev_hub_page.dart.bak_859.* \
    lib/pages/bonusvarsel_dev_hub_page.dart.bak_858.* \
    lib/pages/bonusvarsel_dev_hub_page.dart.bak_830.* \
    2>/dev/null | head -n 1 || true
)"

if [[ -z "$GOOD_DEV_HUB" ]]; then
  echo "❌ Fant ingen kjent god backup for Dev Hub"
  echo "Kjør: ls -1t lib/pages/bonusvarsel_dev_hub_page.dart.bak* | head -n 20"
  exit 1
fi

cp "$GOOD_DEV_HUB" "$DEV_HUB"
echo "✅ Gjenopprettet Dev Hub fra: $GOOD_DEV_HUB"

echo
echo "== Sjekker etter konfliktmarkører =="
if grep -R -nE '^(<<<<<<<|=======|>>>>>>>)' lib/main.dart lib/pages/bonusvarsel_dev_hub_page.dart; then
  echo "❌ Fant fortsatt konfliktmarkører"
  exit 1
else
  echo "✅ Ingen konfliktmarkører i main/dev_hub"
fi

echo
flutter analyze
echo "✅ 876 ferdig"
