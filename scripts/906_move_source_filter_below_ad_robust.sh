#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_906.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

needle = "_buildSourceFilter(context),"

if needle not in text:
    raise SystemExit("❌ Fant ikke _buildSourceFilter(context),")

# fjern første forekomst
idx = text.find(needle)
text = text[:idx] + text[idx + len(needle):]

# rydd opp en typisk tom SizedBox rett før filteret hvis den ble hengende igjen
text = text.replace(
    "        // BV_SOURCE_FILTER\n        const SizedBox(height: 12),\n\n",
    "",
    1,
)
text = text.replace(
    "        const SizedBox(height: 12),\n\n",
    "\n",
    1,
)

insert_before = """          if (_source == 'Alle')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Toppbutikker akkurat nå',
"""

insert = """          const SizedBox(height: 8),
          _buildSourceFilter(context),

"""

if insert_before not in text:
    raise SystemExit("❌ Fant ikke Toppbutikker-blokken å sette filteret foran")

text = text.replace(insert_before, insert + insert_before, 1)

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Flyttet kilde/søk/kategori under annonsen")
PY

flutter analyze
echo "✅ 906 ferdig"
