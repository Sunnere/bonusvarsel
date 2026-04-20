#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_904.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text
changes = []

# 1) Sett default sort til Høy rate hvis _sort finnes
patterns = [
    (r"String\s+_sort\s*=\s*'[^']*';", "String _sort = 'Høy rate';"),
    (r'String\s+_sort\s*=\s*"[^"]*";', 'String _sort = "Høy rate";'),
    (r"var\s+_sort\s*=\s*'[^']*';", "var _sort = 'Høy rate';"),
    (r'var\s+_sort\s*=\s*"[^"]*";', 'var _sort = "Høy rate";'),
]

for pat, repl in patterns:
    new_text = re.sub(pat, repl, text, count=1)
    if new_text != text:
        text = new_text
        changes.append("default sort -> Høy rate")
        break

# 2) Legg inn enkel seksjonstittel over butikklisten når Alle er valgt
old = """          Expanded(
            child: FutureBuilder<List<ShopOffer>>(
"""
new = """          if (_source == 'Alle')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Toppbutikker akkurat nå',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),

          Expanded(
            child: FutureBuilder<List<ShopOffer>>(
"""
if old in text:
    text = text.replace(old, new, 1)
    changes.append("la til seksjonstittel for Alle")
else:
    raise SystemExit("❌ Fant ikke stedet over FutureBuilder-listen")

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Gjorde endringer:")
for c in changes:
    print(" -", c)
PY

flutter analyze
echo "✅ 904 ferdig"
