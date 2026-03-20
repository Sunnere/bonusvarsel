import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../pages/bonusvarsel_paywall_page.dart';

class BonusvarselDevDashboardPage extends StatefulWidget {
  const BonusvarselDevDashboardPage({super.key});

  @override
  State<BonusvarselDevDashboardPage> createState() =>
      _BonusvarselDevDashboardPageState();
}

class _BonusvarselDevDashboardPageState
    extends State<BonusvarselDevDashboardPage> {
  String _log = 'Ingen handlinger enda';

  Future<void> _run(String title, Future<dynamic> Function() action) async {
    setState(() => _log = '$title ...');
    try {
      final result = await action();
      setState(() => _log = '$title\n\n$result');
    } catch (e) {
      setState(() => _log = '$title feilet\n\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonusvarsel Dev Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _run('GET /v1/me', ApiService.getMe),
                child: const Text('GET me'),
              ),
              FilledButton(
                onPressed: () => _run('GET /v1/prefs', ApiService.getPrefs),
                child: const Text('GET prefs'),
              ),
              FilledButton(
                onPressed: () => _run('GET /v1/feed', ApiService.getFeed),
                child: const Text('GET feed'),
              ),
              OutlinedButton(
                onPressed: () => _run(
                  'PUT prefs -> SAS electronics',
                  () => ApiService.updatePrefs(
                    sources: const ['sas'],
                    categories: const ['electronics'],
                    minRate: 10,
                    onlyCampaigns: true,
                    favFirst: false,
                  ),
                ),
                child: const Text('Set SAS electronics'),
              ),
              OutlinedButton(
                onPressed: () => _run(
                  'POST /v1/devices',
                  () => ApiService.registerDevice(
                    token: 'dev-dashboard-token',
                    platform: 'web',
                  ),
                ),
                child: const Text('Register device'),
              ),
              FilledButton.tonal(
                onPressed: () => _run(
                  'SET tier -> free',
                  () => ApiService.setDevTier('free'),
                ),
                child: const Text('Tier free'),
              ),
              FilledButton.tonal(
                onPressed: () => _run(
                  'SET tier -> premium',
                  () => ApiService.setDevTier('premium'),
                ),
                child: const Text('Tier premium'),
              ),
              FilledButton.tonal(
                onPressed: () => _run(
                  'SET tier -> elite',
                  () => ApiService.setDevTier('elite'),
                ),
                child: const Text('Tier elite'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BonusvarselPaywallPage(),
                    ),
                  );
                },
                child: const Text('Åpne paywall'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: SelectableText(_log),
          ),
        ],
      ),
    );
  }
}
