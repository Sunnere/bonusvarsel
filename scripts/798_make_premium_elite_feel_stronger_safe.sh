#!/usr/bin/env bash
set -euo pipefail

echo "==> 798_make_premium_elite_feel_stronger_safe"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_798")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

replacements = [
    (
        "    final premiumLike = true;\n    final eliteLike = false;\n",
        "    final premiumLike = true;\n    final eliteLike = false;\n"
        "    final isUpgraded = premiumLike || eliteLike;\n",
    ),
    (
        "          child: Text(\n            eliteLike\n                ? 'Elite gir mer avanserte forslag og tydeligere partnerprioritet i reisen.'\n                : 'Premium gir raskere vei videre til riktig fly-, hotell- eller leiebilflyt.',\n",
        "          child: Text(\n            eliteLike\n                ? 'Elite gir smartere prioritering, mer eksklusive forslag og raskere vei til beste bookingvalg.'\n                : 'Premium gir bedre forslag, tydeligere verdi og raskere vei videre til riktig fly-, hotell- eller leiebilflyt.',\n",
    ),
    (
        "                      statusLabel,\n",
        "                      eliteLike ? 'Elite aktiv' : 'Premium aktiv',\n",
    ),
    (
        "                      unlockedLine,\n",
        "                      eliteLike\n"
        "                          ? 'Elite: sterkeste prioritering aktivert'\n"
        "                          : 'Premium: bedre forslag og poengverdi aktivert',\n",
    ),
    (
        "                            child: Text(\n                              selected\n                                  ? 'Se beste tilbud'\n                                  : 'Se butikker',\n",
        "                            child: Text(\n                              selected\n                                  ? (eliteLike ? 'Åpne beste valg' : 'Se beste tilbud')\n"
        "                                  : (isUpgraded ? 'Se utvalgte butikker' : 'Se butikker'),\n",
    ),
    (
        "                        Text(\n                          badge,\n",
        "                        Text(\n                          eliteLike\n                              ? 'Elite-valg'\n                              : (premiumLike ? badge : badge),\n",
    ),
    (
        "        gradient: const LinearGradient(\n          colors: [\n            Color(0xFFFFFFFF),\n            Color(0xFFF8FCFD),\n          ],\n",
        "        gradient: LinearGradient(\n          colors: eliteLike\n              ? const [\n                  Color(0xFFFFF8EA),\n                  Color(0xFFF6FBFF),\n                ]\n              : const [\n                  Color(0xFFFFFFFF),\n                  Color(0xFFF8FCFD),\n                ],\n",
    ),
    (
        "        border: Border.all(\n          color: const Color(0xFFDDE8EB),\n          width: 1,\n        ),\n",
        "        border: Border.all(\n          color: eliteLike ? const Color(0xFFE2C675) : const Color(0xFFDDE8EB),\n          width: eliteLike ? 1.2 : 1,\n        ),\n",
    ),
    (
        "              gradient: const LinearGradient(\n                colors: [\n                  Color(0xFF103562),\n                  Color(0xFF1294A4),\n                ],\n",
        "              gradient: LinearGradient(\n                colors: eliteLike\n                    ? const [\n                        Color(0xFF7A5A12),\n                        Color(0xFFE0B94E),\n                      ]\n                    : const [\n                        Color(0xFF103562),\n                        Color(0xFF1294A4),\n                      ],\n",
    ),
    (
        "                  child: Text(\n                    bonus,\n",
        "                  child: Text(\n                    eliteLike\n                        ? 'Elite-prioritet'\n                        : (premiumLike ? bonus : bonus),\n",
    ),
]

changed = 0
for old, new in replacements:
    if old in text:
        text = text.replace(old, new, 1)
        changed += 1

# Add eliteLike parameter to _travelStoreCard signature and calls if missing
sig_old = """  Widget _travelStoreCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> tags,
    required String bonus,
    required String badge,
  }) {
"""
sig_new = """  Widget _travelStoreCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> tags,
    required String bonus,
    required String badge,
    bool premiumLike = true,
    bool eliteLike = false,
  }) {
"""
if sig_old in text:
    text = text.replace(sig_old, sig_new, 1)
    changed += 1

call_old = """                    return _travelStoreCard(
                      context,
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      tags: (item['tags'] as List).cast<String>(),
                      bonus: item['bonus'] as String,
                      badge: item['badge'] as String,
                    );
"""
call_new = """                    return _travelStoreCard(
                      context,
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      tags: (item['tags'] as List).cast<String>(),
                      bonus: item['bonus'] as String,
                      badge: item['badge'] as String,
                      premiumLike: premiumLike,
                      eliteLike: eliteLike,
                    );
"""
if call_old in text:
    text = text.replace(call_old, call_new, 1)
    changed += 1

if changed == 0 or text == orig:
    print("❌ Ingen sikre endringer ble gjort")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 798 ferdig, {changed} endringer brukt")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
