#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")
orig = s

# 1) FilterChip kan ikke være const hvis den bruker state-variabler
s = re.sub(r'\bconst\s+FilterChip\s*\(', 'FilterChip(', s)

# 2) labelStyle/secondaryLabelStyle kan ikke være const hvis farge avhenger av _onlyCampaigns/_favFirst
s = re.sub(r'labelStyle:\s*const\s+TextStyle\s*\(', 'labelStyle: TextStyle(', s)
s = re.sub(r'secondaryLabelStyle:\s*const\s+TextStyle\s*\(', 'secondaryLabelStyle: TextStyle(', s)

# 3) Sikkerhetsnett: fjern "const TextStyle" i blokker som refererer til _onlyCampaigns/_favFirst
def deconst(m):
    return m.group(0).replace("const TextStyle", "TextStyle")

s = re.sub(r'const\s+TextStyle\s*\([\s\S]*?(_onlyCampaigns|_favFirst)[\s\S]*?\)', deconst, s)

if s != orig:
    p.write_text(s, encoding="utf-8")
    print("✅ Patched const issues in", p)
else:
    print("ℹ️ No changes needed")
PY

dart format lib/pages/eb_shopping_page.dart
