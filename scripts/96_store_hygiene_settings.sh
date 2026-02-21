#!/usr/bin/env bash
set -euo pipefail

mkdir -p lib/pages

SETTINGS="lib/pages/settings_page.dart"
[ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)" || true

cat > "$SETTINGS" <<'DART'
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Innstillinger')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Bonusvarsel', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Versjon: 1.0.0 (dev)', style: t.bodyMedium),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Support', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('E-post: sunnerehelse@icloud.com'),
                  const SizedBox(height: 6),
                  const Text('Vi svarer så fort vi kan.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personvern', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Legg inn Privacy Policy URL før App Store/Google Play.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vilkår', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Legg inn Terms URL før lansering.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DART

MAIN="lib/main.dart"
[ -f "$MAIN" ] || { echo "Fant ikke lib/main.dart"; exit 1; }
cp "$MAIN" "$MAIN.bak.$(date +%s)"

python3 - "$MAIN" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# import
if "pages/settings_page.dart" not in s:
  m = re.search(r"^(import .*\n)+", s, flags=re.M)
  if m:
    ins = m.group(0) + "import 'pages/settings_page.dart';\n"
    s = s[:m.start()] + ins + s[m.end():]
  else:
    s = "import 'pages/settings_page.dart';\n" + s

# Prøv å finne MaterialApp(...) og legg inn route for /settings hvis routes finnes,
# ellers legg inn onGenerateRoute fallback.
if "SettingsPage" in s:
  if "routes:" in s:
    # legg til i routes-map hvis ikke finnes
    if "/settings" not in s:
      s = re.sub(
        r"routes:\s*\{",
        "routes: {\n        '/settings': (context) => const SettingsPage(),",
        s,
        count=1
      )
  else:
    # legg inn onGenerateRoute inni MaterialApp hvis ikke finnes
    if "onGenerateRoute:" not in s:
      s = re.sub(
        r"MaterialApp\(",
        "MaterialApp(\n      onGenerateRoute: (settings) {\n        if (settings.name == '/settings') {\n          return MaterialPageRoute(builder: (_) => const SettingsPage());\n        }\n        return null;\n      },",
        s,
        count=1
      )

p.write_text(s, encoding="utf-8")
print("patched main.dart: settings route")
PY

HOME="lib/pages/home_page.dart"
if [[ -f "$HOME" ]]; then
  cp "$HOME" "$HOME.bak.$(date +%s)"
  python3 - "$HOME" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# legg inn import hvis mangler
if "Navigator" not in s and "material.dart" in s:
  pass

# Finn AppBar( ... ) og legg inn actions med settings-knapp hvis ikke finnes
if "Icon(Icons.settings" not in s:
  s2 = re.sub(
    r"AppBar\(([^)]*)\)",
    lambda m: m.group(0) if "actions:" in m.group(0) else m.group(0),
    s,
    count=0
  )

  # enklere: hvis det finnes "appBar: AppBar(" uten actions, injiser actions
  s2 = re.sub(
    r"appBar:\s*AppBar\(\s*([^\)]*?)\)",
    lambda m: m.group(0) if "actions:" in m.group(0) else m.group(0).replace("AppBar(", "AppBar(actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.of(context).pushNamed('/settings')),], "),
    s,
    count=1,
    flags=re.S
  )

  s = s2

p.write_text(s, encoding="utf-8")
print("patched home_page.dart: settings button (best effort)")
PY
fi

dart format "$SETTINGS" "$MAIN" 2>/dev/null || true
[ -f "$HOME" ] && dart format "$HOME" 2>/dev/null || true

echo "✅ 4) Settings/About lagt til + /settings route"
