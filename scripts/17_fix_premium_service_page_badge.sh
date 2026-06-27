#!/usr/bin/env bash
set -euo pipefail

mkdir -p lib/services lib/pages lib/widgets

############################################
# 1) PremiumService – felles API (fallback)
############################################
cat > lib/services/premium_service.dart <<'DART'
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  const PremiumService();

  static const _kIsPremium = 'premium_isPremium';
  static const _kShowBadges = 'premium_showBadges';
  static const _kDebugBadgeEnabled = 'premium_debugBadgeEnabled';
  static const _kFreeLimit = 'premium_freeLimit';

  Future<bool> getIsPremium({bool fallback = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPremium) ?? fallback;
  }

  Future<void> setIsPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, value);
  }

  Future<bool> getShowBadges({bool fallback = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowBadges) ?? fallback;
  }

  Future<void> setShowBadges(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowBadges, value);
  }

  Future<bool> debugBadgeEnabled({bool fallback = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDebugBadgeEnabled) ?? fallback;
  }

  Future<void> setDebugBadgeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDebugBadgeEnabled, value);
  }

  Future<int> getFreeLimit({int fallback = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kFreeLimit) ?? fallback;
  }

  Future<void> setFreeLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFreeLimit, value);
  }
}
DART

############################################
# 2) Premium badge – styres av prefs
############################################
cat > lib/widgets/premium_badge.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class PremiumBadge extends StatelessWidget {
  final PremiumService premium;
  final String label;

  const PremiumBadge({
    super.key,
    this.premium = const PremiumService(),
    this.label = 'PRO',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        premium.getIsPremium(fallback: false),
        premium.getShowBadges(fallback: true),
        premium.debugBadgeEnabled(fallback: true),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final isPrem = (snap.data![0] as bool?) ?? false;
        final showBadges = (snap.data![1] as bool?) ?? true;
        final debugEnabled = (snap.data![2] as bool?) ?? true;

        if (!showBadges) return const SizedBox.shrink();
        if (!isPrem && !debugEnabled) return const SizedBox.shrink();

        return Chip(
          label: Text(label),
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
DART

############################################
# 3) Premium page – admin/debug UI
############################################
cat > lib/pages/premium_page.dart <<'DART'
import 'package:flutter/material.dart';
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
    final isPrem = await _premiumSvc.getIsPremium(fallback: false);
    final showBadges = await _premiumSvc.getShowBadges(fallback: true);
    final freeLimit = await _premiumSvc.getFreeLimit(fallback: 30);
    final dbg = await _premiumSvc.debugBadgeEnabled(fallback: true);

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
                  subtitle: const Text('Simuler PRO (inntil ekte kjøp er på plass)'),
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
                  subtitle: const Text('Nyttig i dev: viser badge selv uten premium'),
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
DART

dart format lib/services/premium_service.dart lib/widgets/premium_badge.dart lib/pages/premium_page.dart
flutter analyze || true

echo "✅ PremiumService + PremiumPage + PremiumBadge oppdatert. Restart web-server hvis den kjører."
