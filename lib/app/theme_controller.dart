import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonusvarsel/models/subscription_tier.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _kTier = 'bv.subs.tier';

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
        return _eliteThemeLightFallback();
    }
  }

  ThemeData get darkTheme {
    if (_tier == SubscriptionTier.elite) return _eliteThemeDark();
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey, brightness: Brightness.dark),
      useMaterial3: true,
    );
  }

  // ─── FREE: Lys hvit/blå – ren og enkel ───────────────────────────────────
  ThemeData _freeTheme() {
    const primary = Color(0xFF1976D2);      // SAS-blå
    const secondary = Color(0xFF42A5F5);    // lyseblå aksent
    const background = Color(0xFFF5F9FF);   // nesten hvit med blåstikk
    const surface = Color(0xFFFFFFFF);

    final cs = ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(color: primary),
        side: const BorderSide(color: primary, width: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerColor: const Color(0xFFE0ECF8),
    );
  }

  // ─── PREMIUM: Grønn – frisk og eksklusiv ─────────────────────────────────
  ThemeData _proTheme() {
    const primary = Color(0xFF1B8A4E);      // dyp grønn
    const secondary = Color(0xFF4CAF50);    // frisk grønn aksent
    const accent = Color(0xFFB9F0C8);       // lys grønn highlight
    const background = Color(0xFFF2FBF5);   // nesten hvit med grønnstikk
    const surface = Color(0xFFFFFFFF);

    final cs = ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      tertiary: accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,
        shadowColor: primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: secondary.withValues(alpha: 0.25), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accent.withValues(alpha: 0.5),
        labelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
        side: BorderSide(color: primary.withValues(alpha: 0.3), width: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
      ),
      dividerColor: const Color(0xFFD4EFE0),
      badgeTheme: const BadgeThemeData(backgroundColor: secondary),
    );
  }

  // ─── ELITE: Mørk luksus – dyp marineblå + gull ───────────────────────────
  ThemeData _eliteThemeDark() {
    const gold = Color(0xFFFFD700);
    const goldLight = Color(0xFFF5E6B3);
    const navy = Color(0xFF0A0E1A);
    const navyCard = Color(0xFF111827);
    const navyAccent = Color(0xFF1E2A3A);
    const purple = Color(0xFF6C3FE0);

    final cs = ColorScheme.dark(
      primary: gold,
      secondary: purple,
      surface: navyCard,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      tertiary: goldLight,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: navy,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: goldLight,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: goldLight,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: navyCard,
        elevation: 8,
        shadowColor: gold.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: gold.withValues(alpha: 0.25), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: navyAccent,
        labelStyle: const TextStyle(color: goldLight, fontWeight: FontWeight.w600),
        side: BorderSide(color: gold.withValues(alpha: 0.4), width: 1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
          shadowColor: gold.withValues(alpha: 0.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      dividerColor: const Color(0xFF1E2A3A),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: goldLight, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFB0BEC5)),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: gold, textColor: Colors.black),
    );
  }

  ThemeData _eliteThemeLightFallback() {
    final cs = ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B21B6), brightness: Brightness.light);
    return ThemeData(useMaterial3: true, colorScheme: cs);
  }
}
