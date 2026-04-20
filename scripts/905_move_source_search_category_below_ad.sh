#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_905.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old_block = """          const _PremiumHeader(),
        // BV_SOURCE_FILTER
        const SizedBox(height: 12),
        _buildSourceFilter(context),

"""

new_block = """          const _PremiumHeader(),

"""

if old_block not in text:
    raise SystemExit("❌ Fant ikke blokken med hero + source filter")

text = text.replace(old_block, new_block, 1)

old_insert = """          if (_source == 'Alle')
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
"""

new_insert = """          const SizedBox(height: 8),
          _buildSourceFilter(context),

          if (_source == 'Alle')
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
"""

if old_insert not in text:
    raise SystemExit("❌ Fant ikke stedet før toppbutikker/listen")

text = text.replace(old_insert, new_insert, 1)

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Flyttet kilde/søk/kategori ned under annonsen")
PY

flutter analyze
echo "✅ 905 ferdig"
