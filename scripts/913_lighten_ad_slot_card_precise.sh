#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/ad_slot.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_913.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/ad_slot.dart")
text = p.read_text()
orig = text

old = """    const navy = BrandTheme.navy;
    const navy2 = BrandTheme.navy2;
    const gold = BrandTheme.gold;
"""
new = """    const navy = Color(0xFF245AA8);
    const navy2 = Color(0xFF163A70);
    const gold = BrandTheme.gold;
"""
if old not in text:
    raise SystemExit("❌ Fant ikke navy/navy2/gold-blokken")
text = text.replace(old, new, 1)

text = text.replace(
"""              color: Colors.black.withValues(alpha: 0.14),""",
"""              color: Colors.black.withValues(alpha: 0.10),""",
1
)

text = text.replace(
"""                          color: Colors.white.withValues(alpha: 0.14),""",
"""                          color: Colors.white.withValues(alpha: 0.22),""",
1
)

text = text.replace(
"""                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),""",
"""                          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),""",
1
)

text = text.replace(
"""                      color: Colors.white70,""",
"""                      color: Colors.white,""",
1
)

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Lysnet annonsekortet presist")
PY

flutter analyze
echo "✅ 913 ferdig"
