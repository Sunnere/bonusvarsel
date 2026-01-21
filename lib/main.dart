import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/mock_campaigns.dart';

void main() {
  runApp(const BonusVarselApp());
}

class BonusVarselApp extends StatelessWidget {
  const BonusVarselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BonusVarsel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AlertsPage(),
    CalculatorPage(),
    PremiumPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BonusVarsel')),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Kampanjer',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Varsler',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Kalkulator',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Premium',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Innstillinger',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke åpne lenken')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Kampanjer',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        for (final c in mockCampaigns)
          Card(
            child: ListTile(
              title: Text('${c.store} • ${c.title}'),
              subtitle: Text(c.details),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.multiplier != null) Chip(label: Text('${c.multiplier}x')),
                  if (c.url != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.open_in_new, size: 22),
                  ],
                ],
              ),
              onTap: c.url == null ? null : () => _open(context, c.url!),
            ),
          ),

        const SizedBox(height: 16),
        const Text('Neste steg: hente ekte SAS-kampanjer automatisk.'),
      ],
    );
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Varsler',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12),
        Bullet('Alle kampanjer'),
        Bullet('Kun valgte butikker'),
        Bullet('Min. boost (f.eks. 6x+)'),
        Bullet('Trumf → EuroBonus-varsler'),
      ],
    );
  }
}

class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalkulator (demo)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Beløp (NOK)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            items: const [
              DropdownMenuItem(value: 1, child: Text('1x')),
              DropdownMenuItem(value: 2, child: Text('2x')),
              DropdownMenuItem(value: 4, child: Text('4x')),
              DropdownMenuItem(value: 6, child: Text('6x')),
              DropdownMenuItem(value: 10, child: Text('10x')),
            ],
            onChanged: (_) {},
            decoration: const InputDecoration(
              labelText: 'Boost',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {},
            child: const Text('Beregn'),
          ),
        ],
      ),
    );
  }
}

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Premium',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12),
        Bullet('49 kr / mnd'),
        Bullet('Tidligere varsler'),
        Bullet('Ubegrensede filtre'),
        Bullet('Flere partnere'),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Innstillinger',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12),
        Bullet('Språk: Norsk'),
        Bullet('Region: Norge'),
        Bullet('Personvern / Vilkår'),
        Bullet('Kontakt / Support'),
      ],
    );
  }
}

class Bullet extends StatelessWidget {
  final String text;
  const Bullet(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}