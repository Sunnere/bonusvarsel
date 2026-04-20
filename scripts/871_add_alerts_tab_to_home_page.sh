#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/home_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_871.$(date +%s)"
echo "✅ Backup laget: $FILE"

cat > "$FILE" <<'DART'
import 'package:flutter/material.dart';
import 'eb_shopping_page.dart';
import 'travel_page.dart';
import 'cards_page.dart';
import 'bonusvarsel_alerts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final _pages = const [
    EbShoppingPage(),
    TravelPage(),
    CardsPage(),
    BonusvarselAlertsPage(),
  ];

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

flutter analyze
echo "✅ 871 ferdig"
