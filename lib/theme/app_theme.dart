import 'package:flutter/material.dart';
import 'package:bonusvarsel/services/entitlement_service.dart';

class AppTheme {
  // ── Gratis tema (navy blå) ────────────────────────────────────────────────
  static const Color bg = Color(0xFF0F2340);
  static const Color surface = Color(0xFF152B4A);
  static const Color surface2 = Color(0xFF1C3860);
  static const Color surface3 = Color(0xFF243F6E);
  static const Color border = Color(0xFF3D6490);

  // ── Premium tema (luksus grønn) ───────────────────────────────────────────
  static const Color bgPremium = Color(0xFF0A1F14);
  static const Color surfacePremium = Color(0xFF0F3020);
  static const Color surface2Premium = Color(0xFF164028);
  static const Color borderPremium = Color(0xFF2D6E45);
  static const Color accentPremium = Color(0xFF34D399);

  // ── Elite tema (luksus lilla/indigo med gull) ─────────────────────────────
  static const Color bgElite = Color(0xFF110A28);
  static const Color surfaceElite = Color(0xFF1A1040);
  static const Color surface2Elite = Color(0xFF241852);
  static const Color borderElite = Color(0xFF4A2D8A);
  static const Color accentElite = Color(0xFFD4AF37);

  static const Color text = Color(0xFFF8FAFC);
  static const Color textSoft = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFFC8D8E8);

  static const Color primary = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color gold = Color(0xFFD4AF37);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);


  /// Returnerer border-farge basert på abonnement
  static Color borderColor(bool isElite, bool isPremium) {
    if (isElite) return const Color(0xFFD4AF37).withOpacity(0.5);
    if (isPremium) return const Color(0xFF34D399).withOpacity(0.4);
    return border;
  }

  /// Returnerer bakgrunnsfarge for bokser basert på abonnement
  static Color boxColor(bool isElite, bool isPremium) {
    if (isElite) return surfaceElite;
    if (isPremium) return surfacePremium;
    return surface;
  }


  /// Returnerer Border basert på abonnement
  static Border activeBorder({bool? forceElite, bool? forcePremium}) {
    final isElite = forceElite ?? EntitlementService.instance.isElite;
    final isPremium = forcePremium ?? EntitlementService.instance.isPremium;
    if (isElite) return Border.all(color: const Color(0xFFD4AF37), width: 1.0);
    if (isPremium) return Border.all(color: const Color(0xFF34D399), width: 0.8);
    return Border.all(color: border, width: 0.8);
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF93C5FD),
        surface: surface,
        error: danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ).copyWith(
        bodyLarge: const TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        bodyMedium: const TextStyle(
          color: textSoft,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
        bodySmall: const TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        titleLarge: const TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleMedium: const TextStyle(
          color: text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleSmall: const TextStyle(
          color: textSoft,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        labelStyle: const TextStyle(
          color: textSoft,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: const TextStyle(
          color: textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(primaryDark),
          foregroundColor: const WidgetStatePropertyAll(text),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.04);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(text),
          backgroundColor: const WidgetStatePropertyAll(surface2),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: border),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.04);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0F2340),
        contentTextStyle: const TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        actionTextColor: const Color(0xFFD4AF37),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: surface3,
        linearTrackColor: surface3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryDark.withValues(alpha: 0.65);
          }
          return surface3;
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(surface2),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: const WidgetStatePropertyAll(
            BorderSide(color: border),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface2,
          labelStyle: const TextStyle(
            color: textSoft,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(
            color: textMuted,
            fontWeight: FontWeight.w600,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.4),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSoft,
        textColor: text,
      ),
      iconTheme: const IconThemeData(
        color: textSoft,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface2,
        selectedColor: surface3,
        disabledColor: surface2,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  static ThemeData premium() {
    final base = dark();
    return base.copyWith(
      scaffoldBackgroundColor: bgPremium,
    );
  }

  static ThemeData elite() {
    final base = dark();
    return base.copyWith(
      scaffoldBackgroundColor: bgElite,
      dividerColor: const Color(0xFFD4AF37).withOpacity(0.3),
      cardTheme: base.cardTheme.copyWith(
        color: surfaceElite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
        ),
      ),
    );
  }


}