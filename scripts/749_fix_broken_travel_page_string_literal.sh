#!/usr/bin/env bash
set -euo pipefail

echo "==> 749_fix_broken_travel_page_string_literal"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_749")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# Fiks ødelagt streng som ble splittet over flere linjer
text = text.replace(
"""                      Text(
                        'Butikktyper som passer best

// fallback hvis tom
// TODO: replace med ekte feed senere',
                        style: _sectionTitleStyle(context),
                      ),""",
"""                      Text(
                        'Butikktyper som passer best',
                        style: _sectionTitleStyle(context),
                      ),"""
)

# Ekstra robust fallback hvis bare starten ble ødelagt
text = re.sub(
    r"Text\(\s*'Butikktyper som passer best\s*(?:\n|.)*?style:\s*_sectionTitleStyle\(context\),\s*\),",
    """Text(
                        'Butikktyper som passer best',
                        style: _sectionTitleStyle(context),
                      ),""",
    text,
    count=1,
    flags=re.DOTALL,
)

if text == original:
    print("No changes made.")
else:
    path.write_text(text)
    print(f"Patched: {path}")
PY

echo
echo "✅ 749 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
