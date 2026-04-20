#!/usr/bin/env bash
set -euo pipefail

FILE="lib/main.dart"
STAMP="$(date +%Y%m%d-%H%M%S)"

cp "$FILE" "${FILE}.bak.${STAMP}"
echo "Backup laget: ${FILE}.bak.${STAMP}"

cat > lib/main.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:bonusvarsel/config/app_env.dart';
import 'package:bonusvarsel/pages/home_page.dart';
import 'package:bonusvarsel/pages/premium_page.dart';
import 'package:bonusvarsel/widgets/onboarding_gate.dart';
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
      home: OnboardingGate(
        trumfUrl: 'https://www.trumf.no/',
        sasUrl: 'https://www.sas.no/eurobonus/',
        onPremiumSelected: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const PremiumPage(),
            ),
          );
        },
        child: const HomePage(),
      ),
    );
  }
}
DART

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter test"
