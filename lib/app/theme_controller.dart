import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonusvarsel/models/subscription_tier.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _kTier = 'bv.subs.tier'; // free/pro/elite

  SubscriptionTier _tier = SubscriptionTier.free;
  SubscriptionTier get tier => _tier;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTier);
    _tier = SubscriptionTierX.fromName(raw);
    notifyListeners();
  }

  Future<void> setTier(SubscriptionTier tier) async {
    _tier = tier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTier, tier.name);
    notifyListeners();
  }

  ThemeMode get themeMode =>
      _tier == SubscriptionTier.elite ? ThemeMode.dark : ThemeMode.light;

  ThemeData get theme {
    switch (_tier) {
      case SubscriptionTier.free:
        return _freeTheme();
      case SubscriptionTier.pro:
        return _proTheme();
      case SubscriptionTier.elite:
        return _eliteThemeLightFallback(); // unused because elite uses darkTheme+ThemeMode.dark
    }
  }

  ThemeData get darkTheme {
    if (_tier == SubscriptionTier.elite) return _eliteThemeDark();
    // fallback dark for other tiers (optional)
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey, brightness: Brightness.dark),
      useMaterial3: true,
    );
  }

  ThemeData _freeTheme() {
    // Minimal / SAS-ish light blue
    final cs = ColorScheme.fromSeed(
        seedColor: const Color(0xFF3BA7FF), brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      chipTheme: const ChipThemeData(),
      cardTheme: CardThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    );
  }

  ThemeData _proTheme() {
    // Premium / psykologisk grønn
    final cs = ColorScheme.fromSeed(
        seedColor: const Color(0xFF22C55E), brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      cardTheme: CardThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    );
  }

  ThemeData _eliteThemeDark() {
    // Tech/Elite / mørk lilla + “gull”
    final cs = ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B21B6), brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF0B0B10),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0B10),
        foregroundColor: Color(0xFFF5E6B3), // “gull”
      ),
      textTheme: const TextTheme(),
      cardTheme: CardThemeData(
        color: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: const Color(0xFF2A2A38),
    );
  }

  ThemeData _eliteThemeLightFallback() {
    // if ThemeMode light forced somehow
    final cs = ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B21B6), brightness: Brightness.light);
    return ThemeData(useMaterial3: true, colorScheme: cs);
  }
}
