#!/usr/bin/env bash
set -euo pipefail

echo "==> 770_repair_broken_budget_block_after_769"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_770")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

pattern = re.compile(
    r"""
                      Text\(
                        cardLabel,
.*?
                      Text\(
                        'Velg\ et\ kort\ i\ "Kort"-siden\ for\ mer\ presis\ beregning\.',
                        style:\ Theme\.of\(context\)\.textTheme\.bodySmall,
                      \),
""",
    re.DOTALL | re.VERBOSE,
)

replacement = """                      Text(
                        cardLabel,
                        style: _travelMutedTextStyle(context).copyWith(
                              color: const Color(0xFF465B63),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Foreløpig estimat',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF35515A),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$estPoints poeng',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                              color: const Color(0xFF0A6E78),
                            ),
                      ),
"""

new_text, count = pattern.subn(replacement, text, count=1)

if count == 0:
    print("❌ Fant ikke budsjettblokka som skulle repareres.")
    print("Kjør dette og send resultatet:")
    print("  sed -n '1288,1328p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(new_text)
print(f"✅ Reparerte budsjettblokka i: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
