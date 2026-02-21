#!/usr/bin/env bash
set -euo pipefail

echo "== Bonusvarsel: A→D patch runner =="

# ---------- helpers ----------
python - <<'PY'
from pathlib import Path
import re

def must(path: str) -> Path:
    p = Path(path)
    if not p.exists():
        raise SystemExit(f"Finner ikke: {path}")
    return p

def backup(p: Path):
    b = p.with_suffix(p.suffix + ".bak")
    if not b.exists():
        b.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# A) Global theme polish (Card, ListTile, Nav, Inputs, Chips)
# ============================================================
p = must("lib/main.dart")
backup(p)
s = p.read_text(encoding="utf-8")

# Ensure we have a theme builder we can safely replace
if "_buildTheme" not in s:
    # If no _buildTheme exists, we inject a minimal one and use it in MaterialApp
    # Try to find `theme:` inside MaterialApp, otherwise just inject _buildTheme and leave.
    pass

# Replace/Insert a robust _buildTheme() implementation
theme_fn = r"ThemeData\s+_buildTheme\(\)\s*\{[\s\S]*?\n\}\n"
new_theme_fn = """ThemeData _buildTheme() {
  const primary = Color(0xFF0A2F6B); // SAS-ish blue
  const secondary = Color(0xFF6C63FF); // subtle creative accent
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: const Color(0xFFF7F8FC),
      background: const Color(0xFFF7F8FC),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    ),

    // A1: Cards feel “premium” (shape + subtle elevation)
    cardTheme: const CardThemeData(
      elevation: 1.2,
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // A2: List tiles & icons
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.black87,
      textColor: Colors.black87,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),

    // A3: Dividers
    dividerTheme: DividerThemeData(
      color: Colors.black.withOpacity(0.06),
      thickness: 1,
      space: 1,
    ),

    // A4: Inputs (search etc)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),

    // A5: Chips – readable selected state (white text on blue)
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      selectedColor: primary,
      disabledColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // A6: Bottom nav – clean + modern
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    // A7: Typography – slightly bolder headings
    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleMedium: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      bodyLarge: const TextStyle(fontWeight: FontWeight.w500),
      bodyMedium: const TextStyle(fontWeight: FontWeight.w500),
    ),
  );
}
"""

if re.search(theme_fn, s):
    s = re.sub(theme_fn, new_theme_fn + "\n", s, count=1)
else:
    # Insert near top (after imports) if missing
    m = re.search(r"(import\s+['\"][^'\"]+['\"];(?:\s*\n))+",
                  s, flags=re.M)
    if not m:
        raise SystemExit("Fant ikke import-blokken i lib/main.dart, kan ikke sette inn _buildTheme() trygt.")
    insert_at = m.end()
    s = s[:insert_at] + "\n" + new_theme_fn + "\n" + s[insert_at:]

# Ensure MaterialApp uses _buildTheme()
# Replace `theme: ...` inside MaterialApp(...) with `theme: _buildTheme(),`
s = re.sub(r"theme:\s*[^,\n]+,",
           "theme: _buildTheme(),",
           s, count=1)

p.write_text(s, encoding="utf-8")
print("✅ A: Theme oppdatert (lib/main.dart)")

# ============================================================
# B) SAS-like “clean enterprise” tweaks (subtle, not a clone)
# ============================================================
p = must("lib/main.dart")
s = p.read_text(encoding="utf-8")
# Make app bar + surfaces even cleaner; keep accent for premium moments
s = s.replace("const secondary = Color(0xFF6C63FF); // subtle creative accent",
              "const secondary = Color(0xFF4B5563); // enterprise neutral accent")
p.write_text(s, encoding="utf-8")
print("✅ B: SAS-clean vibes (secondary justert)")

# ============================================================
# C) Luxury accents (premium elements, not everything)
#    -> We enhance PremiumCard widget appearance
# ============================================================
p = must("lib/widgets/premium_card.dart")
backup(p)
s = p.read_text(encoding="utf-8")

# Wrap existing root with a nicer Card/Container look if not already
# We’ll do a safe-ish patch: find first `return` in build and wrap with Card.
if "LinearGradient" not in s:
    s = re.sub(
        r"return\s+([A-Za-z_][\s\S]*?);",
        "return Card(\n"
        "  elevation: 0,\n"
        "  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),\n"
        "  child: Container(\n"
        "    decoration: BoxDecoration(\n"
        "      borderRadius: BorderRadius.circular(18),\n"
        "      gradient: LinearGradient(\n"
        "        begin: Alignment.topLeft,\n"
        "        end: Alignment.bottomRight,\n"
        "        colors: [Color(0xFF0A2F6B), Color(0xFF111827)],\n"
        "      ),\n"
        "    ),\n"
        "    child: Padding(\n"
        "      padding: const EdgeInsets.all(16),\n"
        "      child: $1,\n"
        "    ),\n"
        "  ),\n"
        ");",
        s,
        count=1,
    )

# Ensure text is white-ish inside (best-effort: common TextStyle patch)
s = s.replace("color: Colors.black", "color: Colors.white")
s = s.replace("color: Colors.black87", "color: Colors.white")
p.write_text(s, encoding="utf-8")
print("✅ C: PremiumCard gjort mer luksus (gradient + hvit tekst)")

# ============================================================
# D) Premium “lock flow” (lightweight / placeholder)
#    -> Add a PremiumPage + route, no payments yet
# ============================================================
premium_page = Path("lib/pages/premium_page.dart")
if not premium_page.exists():
    premium_page.write_text(
"""import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _premium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _premium = prefs.getBool('is_premium') ?? false);
  }

  Future<void> _toggleForNow() async {
    final prefs = await SharedPreferences.getInstance();
    final next = !_premium;
    await prefs.setBool('is_premium', next);
    setState(() => _premium = next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bonusvarsel Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_premium ? Icons.verified : Icons.lock_outline, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _premium
                            ? 'Premium er aktivert (test-toggle).'
                            : 'Premium er låst (test-toggle).',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Premium gir deg:', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('• Push-varsel på kampanjer'),
                    Text('• Favoritter + filtrering + historikk'),
                    Text('• Bedre søk og “best value”'),
                    Text('• (Senere) pris/poeng-kalkulator + kort-optimalisering'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _toggleForNow,
                child: Text(_premium ? 'Deaktiver (test)' : 'Aktiver (test)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
""",
        encoding="utf-8",
    )
    print("✅ D: Opprettet lib/pages/premium_page.dart")

# Add route + tiny entry point from PremiumCard tap (safe fallback)
p = must("lib/main.dart")
s = p.read_text(encoding="utf-8")
if "premium_page.dart" not in s:
    s = re.sub(r"(import\s+['\"]pages/home_page\.dart['\"];)",
               r"\1\nimport 'pages/premium_page.dart';",
               s, count=1)

# Add routes: { '/premium': (_) => const PremiumPage(), }
if "routes:" not in s:
    s = re.sub(r"MaterialApp\(",
               "MaterialApp(\n      routes: {\n        '/premium': (_) => const PremiumPage(),\n      },",
               s, count=1)
else:
    if "/premium" not in s:
        s = re.sub(r"routes:\s*\{",
                   "routes: {\n        '/premium': (_) => const PremiumPage(),",
                   s, count=1)

p.write_text(s, encoding="utf-8")
print("✅ D: Route /premium lagt til i main.dart")

# Patch PremiumCard to navigate to /premium on tap (best effort)
p = must("lib/widgets/premium_card.dart")
s = p.read_text(encoding="utf-8")
if "Navigator.pushNamed" not in s:
    # wrap top-level returned widget with InkWell if possible
    s = re.sub(
        r"return\s+Card\(",
        "return InkWell(\n"
        "  borderRadius: BorderRadius.circular(18),\n"
        "  onTap: () => Navigator.pushNamed(context, '/premium'),\n"
        "  child: Card(",
        s,
        count=1,
    )
    # close InkWell if not already
    if "child: Card(" in s and "Navigator.pushNamed" in s and not s.rstrip().endswith(");"):
        pass
    # Add closing for InkWell if missing (heuristic: after first `);` that closes Card-return)
    # We do a conservative replace: first occurrence of "\n);" at end of return statement
    s = s.replace("\n);", "\n  ),\n);", 1)

p.write_text(s, encoding="utf-8")
print("✅ D: PremiumCard -> åpner /premium ved trykk")

print("✅ Ferdig: A→D patches applied")
PY

echo "== Format =="
dart format lib/main.dart lib/pages/eb_shopping_page.dart lib/widgets/premium_card.dart lib/pages/premium_page.dart || true

echo "== Analyze (ikke stopp på warnings) =="
flutter analyze || true

echo "== Restart web-server (8080) =="
kill $(lsof -ti :8080) 2>/dev/null || true
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
