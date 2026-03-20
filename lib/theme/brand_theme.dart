import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Brand palette (psychology):
/// - Navy: trust, stability, aviation
/// - Gold: premium, reward, status
/// - Soft surfaces: calm, readability
class BrandTheme {
  static const Color navy = Color(0xFF0B1B3A);
  static const Color navy2 = Color(0xFF102A5C);
  static const Color gold = Color(0xFFD4AF37);

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: navy,
      secondary: gold,
      tertiary: navy2,
      surface: const Color(0xFFF7F8FA),
      surfaceContainerHighest: const Color(0xFFF0F2F5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandTheme.navy,
        foregroundColor: BrandTheme.gold,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.dark,
    ).copyWith(
      primary: navy2,
      secondary: gold,
      surface: const Color(0xFF0A0F1E),
      surfaceContainerHighest: const Color(0xFF111A2E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandTheme.navy,
        foregroundColor: BrandTheme.gold,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
