#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_756_wire_paywall_preview_into_app"

if [ ! -f "lib/paywall/paywall_preview_page.dart" ]; then
  echo "❌ Mangler paywall-preview fra forrige steg:"
  echo "   lib/paywall/paywall_preview_page.dart"
  echo
  echo "Kjør først:"
  echo "   bash scripts/patch_755_create_paywall_design_and_copy.sh"
  exit 1
fi

mkdir -p lib/paywall

cat > lib/paywall/paywall_launcher_button.dart <<'DART'
import 'package:flutter/material.dart';
import 'paywall_preview_page.dart';

class PaywallLauncherButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;

  const PaywallLauncherButton({
    super.key,
    this.tooltip = 'Test Premium paywall',
    this.icon = Icons.workspace_premium_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PaywallPreviewPage(),
          ),
        );
      },
    );
  }
}
DART

cat > lib/paywall/paywall_test_entry_page.dart <<'DART'
import 'package:flutter/material.dart';
import 'paywall_preview_page.dart';

class PaywallTestEntryPage extends StatelessWidget {
  const PaywallTestEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04152A),
      appBar: AppBar(
        title: const Text('Paywall test'),
        backgroundColor: const Color(0xFF04152A),
      ),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.workspace_premium_rounded),
          label: const Text('Åpne Premium paywall'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PaywallPreviewPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}
DART

python3 <<'PY'
from pathlib import Path
import re
from datetime import datetime

targets = [
    Path("lib/pages/eb_shopping_page.dart"),
    Path("lib/pages/premium_page.dart"),
]

import_line = "import '../paywall/paywall_preview_page.dart';"
launcher_import = "import '../paywall/paywall_launcher_button.dart';"

injection = """PaywallLauncherButton(
                tooltip: 'Test Premium paywall',
              ),
              """

patched_any = False
report = []

for path in targets:
    if not path.exists():
        report.append(f"SKIP {path} (finnes ikke)")
        continue

    original = path.read_text()
    text = original

    backup = path.with_suffix(path.suffix + f".bak_756_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    backup.write_text(original)

    if "paywall_preview_page.dart" not in text and "paywall_launcher_button.dart" not in text:
        # Try to place import next to local imports
        imports = re.findall(r"^import .+?;\n", text, flags=re.MULTILINE)
        if imports:
            last_import = imports[-1]
            if launcher_import not in text:
                text = text.replace(last_import, last_import + launcher_import + "\n", 1)
        else:
            text = launcher_import + "\n" + text

    # Avoid double injection
    if "PaywallLauncherButton(" in text:
        path.write_text(text)
        report.append(f"OK   {path} (allerede wired)")
        patched_any = True
        continue

    # Try to inject into the first actions: [ block
    marker = "actions: ["
    idx = text.find(marker)
    if idx != -1:
        insert_at = idx + len(marker)
        text = text[:insert_at] + "\n              " + injection + text[insert_at:]
        path.write_text(text)
        report.append(f"OK   {path} (AppBar action wired)")
        patched_any = True
        continue

    # Fallback: add a floating action button to the first Scaffold(
    scaffold_marker = "Scaffold("
    sidx = text.find(scaffold_marker)
    if sidx != -1 and "floatingActionButton:" not in text:
        # naive but safe enough: inject right after Scaffold(
        replacement = """Scaffold(
      floatingActionButton: PaywallLauncherButton(
        tooltip: 'Test Premium paywall',
      ),
"""
        text = text.replace("Scaffold(\n", replacement, 1)
        path.write_text(text)
        report.append(f"OK   {path} (floatingActionButton wired)")
        patched_any = True
        continue

    path.write_text(text)
    report.append(f"WARN {path} (ingen auto-wire, kun import/backup)")

Path("lib/paywall/_patch_756_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
print(f"\npatched_any={patched_any}")
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_756_report.txt

echo
echo "✅ Ferdig"
echo
echo "Dette ble laget:"
echo " - lib/paywall/paywall_launcher_button.dart"
echo " - lib/paywall/paywall_test_entry_page.dart"
echo
echo "Neste:"
echo "1) kjør flutter analyze"
echo "2) åpne skjermen der knappen ble wired"
echo "3) trykk diamant/premium-knappen i appbaren"
echo
echo "Hvis ingen knapp dukket opp, bruk denne midlertidig i en valgfri side:"
echo "  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallTestEntryPage()));"
