#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/main.dart")
s = p.read_text(encoding="utf-8")

PRIMARY = "const Color(0xFF0A2F6B)"   # SAS-ish blå
ACCENT  = "const Color(0xFF6C63FF)"  # lilla accent

# 1) Sørg for at vi har import av material (skal allerede være der)
if "package:flutter/material.dart" not in s:
  s = "import 'package:flutter/material.dart';\n" + s

# 2) Erstatt/legg inn en stabil _buildTheme() (Material 3)
theme_fn = r"ThemeData\s+_buildTheme\s*\(\s*\)\s*\{[\s\S]*?\n\}"
replacement = f"""ThemeData _buildTheme() {{
  final primary = {PRIMARY};
  final accent = {ACCENT};

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    secondary: accent,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    ),

    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      selectedColor: primary,
      disabledColor: Colors.grey.shade100,
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      // NB: selected chips får hvit tekst via widgeten (vi patcher det også i eb_shopping_page i D)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.transparent),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    ),
  );
}}"""

if re.search(theme_fn, s, flags=re.MULTILINE):
  s = re.sub(theme_fn, replacement, s, count=1, flags=re.MULTILINE)
else:
  # Hvis _buildTheme ikke finnes, legg den inn før main()
  s = re.sub(r"\nvoid\s+main\s*\(", "\n" + replacement + "\n\nvoid main(", s, count=1)

# 3) Sørg for at MaterialApp bruker theme: _buildTheme()
# (erstatt theme: ThemeData(...) eller theme: ThemeData( ... ) til _buildTheme())
s = re.sub(r"theme:\s*ThemeData\([\s\S]*?\)\s*,", "theme: _buildTheme(),", s, count=1)
if "theme: _buildTheme()" not in s:
  s = re.sub(r"(return\s+MaterialApp\()\s*", r"\1\n      theme: _buildTheme(),\n", s, count=1)

p.write_text(s, encoding="utf-8")
print("✅ B: Global theme patchet i lib/main.dart")
PY

dart format lib/main.dart
