#!/usr/bin/env bash
set -euo pipefail

mkdir -p scripts lib/pages

# 1) Lag/erstatt premium_page.dart (trygg, enkel placeholder)
cat > lib/pages/premium_page.dart <<'EOF'
import 'package:flutter/material.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Her kommer paywall/fordeler. (Placeholder)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: cs.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Premium gir deg flere filtre, varsler og bedre oversikt.',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kjøp/abonnement kommer i steg D/E 😉')),
                );
              },
              icon: const Icon(Icons.lock_open),
              label: const Text('Aktiver Premium (kommer)'),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

# 2) Patch eb_shopping_page.dart: import + AppBar-knapp
python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# Import
if "premium_page.dart" not in s:
    # legg import etter første import-blokk
    m = re.search(r"(import\s+['\"][^'\"]+['\"];\s*\n)+", s)
    if m:
        block = m.group(0)
        if "import 'premium_page.dart';" not in block:
            block2 = block + "import 'premium_page.dart';\n"
            s = s[:m.start()] + block2 + s[m.end():]
    else:
        s = "import 'premium_page.dart';\n" + s

# AppBar actions knapp (kun hvis actions finnes)
if "PremiumPage(" not in s:
    # Finn AppBar(... actions: [ ... ])
    # Vi prøver å legge inn IconButton helt først i actions-listen
    def inject_actions(match: re.Match) -> str:
        inner = match.group(1)
        # hvis allerede en premium-knapp-lignende finnes, ikke gjør noe
        if "workspace_premium" in inner or "Premium" in inner:
            return match.group(0)
        button = (
            "IconButton(\n"
            "            tooltip: 'Premium',\n"
            "            icon: const Icon(Icons.workspace_premium),\n"
            "            onPressed: () {\n"
            "              Navigator.of(context).push(\n"
            "                MaterialPageRoute(builder: (_) => const PremiumPage()),\n"
            "              );\n"
            "            },\n"
            "          ),\n"
            "          "
        )
        return "actions: [" + button + inner + "]"

    s2, n = re.subn(r"actions:\s*\[\s*(.*?)\s*\]", inject_actions, s, count=1, flags=re.S)
    s = s2

p.write_text(s, encoding="utf-8")
print("✅ PremiumPage laget + knapp forsøkt injisert i AppBar (eb_shopping_page.dart)")
PY

dart format lib/pages/premium_page.dart lib/pages/eb_shopping_page.dart
flutter analyze
