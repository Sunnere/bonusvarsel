#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_757_wire_paywall_to_concrete_triggerpoints"

TARGET="lib/pages/eb_shopping_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  echo "Denne patchen er laget for eb_shopping_page.dart."
  exit 1
fi

if [ ! -f "lib/paywall/paywall_preview_page.dart" ]; then
  echo "❌ Mangler paywall-preview:"
  echo "   lib/paywall/paywall_preview_page.dart"
  echo "Kjør først:"
  echo "   bash scripts/patch_755_create_paywall_design_and_copy.sh"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_757_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget: $TARGET.bak_757_*"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()

report = []

# 1) import
import_line = "import '../paywall/paywall_preview_page.dart';"
if "paywall_preview_page.dart" not in text:
    imports = list(re.finditer(r"^import .+?;\n", text, flags=re.MULTILINE))
    if imports:
        last = imports[-1]
        text = text[:last.end()] + import_line + "\n" + text[last.end():]
    else:
        text = import_line + "\n" + text
    report.append("la til import for paywall_preview_page.dart")

# 2) helper method in State class
helper = """
  void _openPremiumPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallPreviewPage(),
      ),
    );
  }

"""
if "_openPremiumPaywall()" not in text:
    m = re.search(r"(class\s+_?[A-Za-z0-9_]*State\s+extends\s+State<[^>]+>\s*\{)", text)
    if m:
        text = text[:m.end()] + "\n" + helper + text[m.end():]
        report.append("la til _openPremiumPaywall()-helper")
    else:
        report.append("ADVARSEL: fant ikke State-klasse for helper")

# 3) concrete triggerpoint replacements
replacements = []

# A: TextButton/OutlinedButton/ElevatedButton child text patterns
button_patterns = [
    (
        r"(\b(?:TextButton|OutlinedButton|ElevatedButton)\.icon?\s*\(\s*[^;]*?onPressed:\s*)([^,]+)(,\s*[^;]*?(?:'Boost i Premium'|\"Boost i Premium\")[^;]*?\))",
        r"\1() => _openPremiumPaywall()\3",
        "wiret eksisterende knapp med teksten 'Boost i Premium'"
    ),
    (
        r"(\b(?:TextButton|OutlinedButton|ElevatedButton)\.icon?\s*\(\s*[^;]*?onPressed:\s*)([^,]+)(,\s*[^;]*?(?:'Elite'|\"Elite\")[^;]*?\))",
        r"\1() => _openPremiumPaywall()\3",
        "wiret eksisterende knapp med teksten 'Elite'"
    ),
    (
        r"(\b(?:TextButton|OutlinedButton|ElevatedButton)\.icon?\s*\(\s*[^;]*?onPressed:\s*)([^,]+)(,\s*[^;]*?(?:'Premium'|\"Premium\")[^;]*?\))",
        r"\1() => _openPremiumPaywall()\3",
        "wiret eksisterende knapp med teksten 'Premium'"
    ),
]

for pattern, repl, msg in button_patterns:
    new_text, n = re.subn(pattern, repl, text, flags=re.DOTALL)
    if n > 0:
        text = new_text
        report.append(f"{msg} ({n} treff)")

# B: generic GestureDetector / InkWell around premium labels with onTap null-ish
tap_patterns = [
    (
        r"(onTap:\s*)(null|(?:\(\)\s*\{\s*\})|(?:\(\)\s*=>\s*null))([^;]*?(?:'Boost i Premium'|\"Boost i Premium\"))",
        r"\1() => _openPremiumPaywall()\3",
        "wiret onTap ved 'Boost i Premium'"
    ),
    (
        r"(onTap:\s*)(null|(?:\(\)\s*\{\s*\})|(?:\(\)\s*=>\s*null))([^;]*?(?:'Elite'|\"Elite\"))",
        r"\1() => _openPremiumPaywall()\3",
        "wiret onTap ved 'Elite'"
    ),
]

for pattern, repl, msg in tap_patterns:
    new_text, n = re.subn(pattern, repl, text, flags=re.DOTALL)
    if n > 0:
        text = new_text
        report.append(f"{msg} ({n} treff)")

# C: direct string CTA replacement with clickable TextButton fallback
string_cta_patterns = [
    (
        r"Text\(\s*'Boost i Premium'\s*([,\)])",
        "TextButton(onPressed: _openPremiumPaywall, child: const Text('Boost i Premium'))",
        "erstattet ren 'Boost i Premium'-tekst med klikkbar TextButton"
    ),
    (
        r'Text\(\s*"Boost i Premium"\s*([,\)])',
        'TextButton(onPressed: _openPremiumPaywall, child: const Text("Boost i Premium"))',
        "erstattet ren 'Boost i Premium'-tekst med klikkbar TextButton"
    ),
]

for pattern, repl, msg in string_cta_patterns:
    new_text, n = re.subn(pattern, repl, text)
    if n > 0:
        text = new_text
        report.append(f"{msg} ({n} treff)")

# 4) Safe fallback: add AppBar action if no concrete triggerpoint was matched
had_concrete = any("wiret" in r or "erstattet" in r for r in report)

if "PaywallPreviewPage" in text and not had_concrete:
    # Try to add import for launcher icon dependency via direct IconButton inside actions
    # Case 1: existing actions list in first AppBar
    marker = "actions: ["
    idx = text.find(marker)
    if idx != -1 and "workspace_premium_rounded" not in text:
        insert = """
            IconButton(
              tooltip: 'Premium',
              onPressed: _openPremiumPaywall,
              icon: const Icon(Icons.workspace_premium_rounded),
            ),
"""
        text = text[:idx + len(marker)] + "\n" + insert + text[idx + len(marker):]
        report.append("fallback: la til Premium-knapp i AppBar")
        had_concrete = True

# 5) If still nothing, inject a floating button in first Scaffold
if not had_concrete and "floatingActionButton: FloatingActionButton.extended(" not in text:
    scaffold_pattern = r"Scaffold\("
    m = re.search(scaffold_pattern, text)
    if m:
        inject = """Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPremiumPaywall,
        icon: const Icon(Icons.workspace_premium_rounded),
        label: const Text('Premium'),
      ),
"""
        text = text.replace("Scaffold(\n", inject, 1)
        report.append("fallback: la til FloatingActionButton for Premium")
        had_concrete = True

path.write_text(text)

report_path = Path("lib/paywall/_patch_757_report.txt")
report_path.write_text("\n".join(report) + "\n")

print("\n".join(report) if report else "ingen endringer skrevet")
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_757_report.txt || true

echo
echo "✅ Ferdig"
echo "Neste:"
echo "1) flutter analyze"
echo "2) åpne eb_shopping_page"
echo "3) test Premium-triggeren"
echo
echo "Hvis du vil se nøyaktig hva som ble endret:"
echo "  sed -n '1,260p' lib/pages/eb_shopping_page.dart"
