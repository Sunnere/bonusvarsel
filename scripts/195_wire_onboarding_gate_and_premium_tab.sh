#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

for FILE in lib/main.dart lib/pages/home_page.dart; do
  if [ ! -f "$FILE" ]; then
    echo "Fant ikke $FILE"
    exit 1
  fi
  cp "$FILE" "${FILE}.bak.${STAMP}"
  echo "Backup laget: ${FILE}.bak.${STAMP}"
done

cat > lib/pages/home_page.dart <<'DART'
import 'package:flutter/material.dart';
import 'eb_shopping_page.dart';
import 'travel_page.dart';
import 'cards_page.dart';
import 'bonusvarsel_alerts_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _index;

  final _pages = const [
    EbShoppingPage(),
    TravelPage(),
    CardsPage(),
    BonusvarselAlertsPage(),
  ];

  @override
  void initState() {
    super.initState();
    final idx = widget.initialIndex;
    _index = (idx >= 0 && idx < _pages.length) ? idx : 0;
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      final idx = widget.initialIndex;
      _index = (idx >= 0 && idx < _pages.length) ? idx : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Shopping',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_outlined),
            selectedIcon: Icon(Icons.flight),
            label: 'Reis',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Kort',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Varsler',
          ),
        ],
      ),
    );
  }
}
DART

cat > lib/main.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:bonusvarsel/config/app_env.dart';
import 'package:bonusvarsel/pages/home_page.dart';
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
              builder: (_) => const HomePage(initialIndex: 2),
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
