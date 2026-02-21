import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final PremiumService _premiumSvc = const PremiumService();

  bool _loading = true;

  bool _isPremium = false;
  bool _showBadges = true;
  bool _debugBadgeEnabled = true;
  int _freeLimit = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isPrem = await _premiumSvc.getIsPremium();
    final showBadges = await _premiumSvc.getShowBadges(fallback: true);
    final freeLimit = await _premiumSvc.getFreeLimit(fallback: 30);
    final dbg = await _premiumSvc.debugBadgeEnabled();

    if (!mounted) return;
    setState(() {
      _isPremium = isPrem;
      _showBadges = showBadges;
      _freeLimit = freeLimit;
      _debugBadgeEnabled = dbg;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _premiumSvc.setIsPremium(_isPremium);
    await _premiumSvc.setShowBadges(_showBadges);
    await _premiumSvc.setFreeLimit(_freeLimit);
    await _premiumSvc.setDebugBadgeEnabled(_debugBadgeEnabled);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lagret ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        actions: [
          IconButton(
            tooltip: 'Lagre',
            onPressed: _loading ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _debugBadgeEnabled,
                    onChanged: (v) async {
                      setState(() => _debugBadgeEnabled = v);
                      await _premiumSvc.setDebugBadgeEnabled(v);
                    },
                    title: const Text('Debug-badge override'),
                    subtitle: const Text(
                        'Vis PRO-badge selv uten premium (kun debug).'),
                  ),
                ],
                Text(
                  'Admin / debug',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Her kan DU styre premium-flag, free-limit og badge.\n'
                  'I prod kan du skjule debug-kontroller og koble på ekte kjøp senere.',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Premium aktiv'),
                  subtitle:
                      const Text('Simuler PRO (inntil ekte kjøp er på plass)'),
                  value: _isPremium,
                  onChanged: (v) => setState(() => _isPremium = v),
                ),
                SwitchListTile(
                  title: const Text('Vis badge'),
                  subtitle: const Text('Slå av/på PRO-badge (for alle)'),
                  value: _showBadges,
                  onChanged: (v) => setState(() => _showBadges = v),
                ),
                SwitchListTile(
                  title: const Text('Debug-badge når ikke premium'),
                  subtitle:
                      const Text('Nyttig i dev: viser badge selv uten premium'),
                  value: _debugBadgeEnabled,
                  onChanged: (v) => setState(() => _debugBadgeEnabled = v),
                ),
                const Divider(height: 32),
                Text(
                  'Free-limit: $_freeLimit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  min: 5,
                  max: 200,
                  divisions: 195,
                  value: _freeLimit.toDouble(),
                  label: '$_freeLimit',
                  onChanged: (v) => setState(() => _freeLimit = v.round()),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Lagre'),
                ),
              ],
            ),
    );
  }
}
