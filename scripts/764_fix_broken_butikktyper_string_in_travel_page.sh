#!/usr/bin/env bash
set -euo pipefail

echo "==> 764_fix_broken_butikktyper_string_in_travel_page"

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
bak = path.with_name(path.name + f".bak_{stamp}_764")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Fiks den konkrete ødelagte blokken hvis hele feilblokken finnes
broken_block = """                      Text(
                        'Butikktyper som passer best

// fallback hvis tom
// TODO: replace med ekte feed senere',
                        style: _sectionTitleStyle(context),
                      ),"""

fixed_block = """                      Text(
                        'Butikktyper som passer best',
                        style: _sectionTitleStyle(context),
                      ),"""

text = text.replace(broken_block, fixed_block)

# 2) Ekstra robust fallback: alt fra Text('Butikktyper... til style-linjen
text = re.sub(
    r"Text\(\s*'Butikktyper som passer best(?:.|\n)*?style:\s*_sectionTitleStyle\(context\),\s*\),",
    """Text(
                        'Butikktyper som passer best',
                        style: _sectionTitleStyle(context),
                      ),""",
    text,
    count=1,
    flags=re.DOTALL,
)

if text == original:
    print("Ingen endringer gjort.")
else:
    path.write_text(text)
    print(f"✅ Patched: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
