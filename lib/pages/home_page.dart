import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'eb_shopping_page.dart';
import 'travel_page.dart';
import 'cards_page.dart';
import 'bonusvarsel_alerts_page.dart';
import '../services/onboarding_service.dart';
import '../widgets/paywall_scroll_wrapper.dart';

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
    PaywallScrollWrapper(child: EbShoppingPage()),
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

  Future<void> _resetOnboardingForDebug() async {
    await OnboardingService.reset();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Onboarding nullstilt. Lukk og åpne appen igjen.'),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (!kDebugMode) return null;

    return AppBar(
      title: const Text('Bonusvarsel'),
      actions: [
        IconButton(
          tooltip: 'Nullstill onboarding',
          onPressed: _resetOnboardingForDebug,
          icon: const Icon(Icons.bug_report_outlined),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
