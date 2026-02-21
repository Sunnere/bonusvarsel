#!/usr/bin/env bash
set -euo pipefail

mkdir -p lib/services lib/pages lib/widgets

############################################
# 1) PremiumService - EN felles sannhet API
############################################
cat > lib/services/premium_service.dart <<'DART'
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  const PremiumService();

  static const _kIsPremium = 'premium_is_premium';
  static const _kFreeLimit = 'premium_free_limit';
  static const _kShowBadges = 'premium_show_badges';

  // Admin/debug-only toggles
  static const _kDebugBadgeEnabled = 'debug_badge_enabled';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> getIsPremium() async {
    final p = await _prefs;
    return p.getBool(_kIsPremium) ?? false;
  }

  Future<void> setIsPremium(bool v) async {
    final p = await _prefs;
    await p.setBool(_kIsPremium, v);
  }

  /// Alias som matcher kode du allerede har hatt inne
  Future<void> setPremiumForDebug(bool v) => setIsPremium(v);

  Future<int> getFreeLimit({int fallback = 30}) async {
    final p = await _prefs;
    final v = p.getInt(_kFreeLimit);
    if (v == null) return fallback;
    // litt hygiene
    if (v < 5) return 5;
    if (v > 500) return 500;
    return v;
  }

  Future<void> setFreeLimit(int v) async {
    final p = await _prefs;
    final clamped = v.clamp(5, 500);
    await p.setInt(_kFreeLimit, clamped);
  }

  Future<bool> getShowBadges({bool fallback = true}) async {
    final p = await _prefs;
    return p.getBool(_kShowBadges) ?? fallback;
  }

  Future<void> setShowBadges(bool v) async {
    final p = await _prefs;
    await p.setBool(_kShowBadges, v);
  }

  /// Debug/admin: kunne slå av/på badge uavhengig av premium.
  /// I release kan du velge å alltid returnere true/false – her lar vi det være mulig,
  /// men skjuler UI i PremiumPage når !kDebugMode.
  Future<bool> debugBadgeEnabled({bool fallback = true}) async {
    final p = await _prefs;
    return p.getBool(_kDebugBadgeEnabled) ?? fallback;
  }

  Future<void> setDebugBadgeEnabled(bool v) async {
    final p = await _prefs;
    await p.setBool(_kDebugBadgeEnabled, v);
  }

  /// Placeholder til du kobler på RevenueCat/IAP etc.
  Future<void> restore() async {
    // no-op for now
  }
}
DART

############################################
# 2) PremiumBadge - robust + admin toggle
############################################
cat > lib/widgets/premium_badge.dart <<'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class PremiumBadge extends StatelessWidget {
  final PremiumService premium;
  final double size;

  const PremiumBadge({
    super.key,
    this.premium = const PremiumService(),
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShow(),
      builder: (context, snap) {
        final show = snap.data ?? false;
        if (!show) return const SizedBox.shrink();

        return Tooltip(
          message: 'Premium',
          child: Icon(Icons.workspace_premium, size: size),
        );
      },
    );
  }

  Future<bool> _shouldShow() async {
    // Først: global “show badges”
    final showBadges = await premium.getShowBadges(fallback: true);
    if (!showBadges) return false;

    // Debug/admin kan skru badge helt av/på (skjult i release UI)
    if (kDebugMode) {
      final dbg = await premium.debugBadgeEnabled(fallback: true);
      if (!dbg) return false;
    }

    // Badge vises om du faktisk er premium
    return premium.getIsPremium();
  }
}
DART

############################################
# 3) PremiumPage - admin panel (debug)
############################################
cat > lib/pages/premium_page.dart <<'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final PremiumService _premium = const PremiumService();

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
    final isPrem = await _premium.getIsPremium();
    final showBadges = await _premium.getShowBadges(fallback: true);
    final freeLimit = await _premium.getFreeLimit(fallback: 30);
    final dbg = kDebugMode ? await _premium.debugBadgeEnabled(fallback: true) : true;

    if (!mounted) return;
    setState(() {
      _isPremium = isPrem;
      _showBadges = showBadges;
      _freeLimit = freeLimit;
      _debugBadgeEnabled = dbg;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Admin / debug', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Her kan DU styre premium-flagg, free-limit og badge. '
                  'I prod kan du skjule debug-kontroller og koble på ekte kjøp.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Premium flagg (debug/admin)
                Card(
                  child: SwitchListTile(
                    title: const Text('Sett meg som Premium (debug)'),
                    value: _isPremium,
                    onChanged: (v) async {
                      setState(() => _isPremium = v);
                      await _premium.setPremiumForDebug(v);
                    },
                  ),
                ),

                // Free limit
                Card(
                  child: ListTile(
                    title: const Text('Gratis-limit (antall butikker)'),
                    subtitle: Text('$_freeLimit'),
                    trailing: SizedBox(
                      width: 220,
                      child: Slider(
                        value: _freeLimit.toDouble(),
                        min: 5,
                        max: 200,
                        divisions: 195,
                        onChanged: (v) async {
                          final vv = v.round();
                          setState(() => _freeLimit = vv);
                          await _premium.setFreeLimit(vv);
                        },
                      ),
                    ),
                  ),
                ),

                // Show badges global
                Card(
                  child: SwitchListTile(
                    title: const Text('Vis premium-badges (globalt)'),
                    value: _showBadges,
                    onChanged: (v) async {
                      setState(() => _showBadges = v);
                      await _premium.setShowBadges(v);
                    },
                  ),
                ),

                // Debug badge enabled (kun debug)
                if (kDebugMode)
                  Card(
                    child: SwitchListTile(
                      title: const Text('Debug: badge aktiv'),
                      subtitle: const Text('Skru badge helt av/på uten å endre premium'),
                      value: _debugBadgeEnabled,
                      onChanged: (v) async {
                        setState(() => _debugBadgeEnabled = v);
                        await _premium.setDebugBadgeEnabled(v);
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // Restore placeholder
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore purchases (placeholder)'),
                  onPressed: () async {
                    await _premium.restore();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          kDebugMode
                              ? 'Restore: no-op (kobles på RevenueCat/IAP senere)'
                              : 'Restore: ikke aktivert enda',
                        ),
                        backgroundColor: cs.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
DART

############################################
# 4) Format + analyze
############################################
dart format lib/services/premium_service.dart lib/widgets/premium_badge.dart lib/pages/premium_page.dart
flutter analyze || true

echo "✅ PremiumService + PremiumPage + PremiumBadge skrevet på nytt."
echo "➡️ Restart web-server hvis den kjører."
