#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_852.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old_block = """              final title = item['title']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';

              return Container(
"""

new_block = """              final title = item['title']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final businessScore = item['businessScore']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';

              return Container(
"""

if old_block not in text:
    raise SystemExit("❌ Fant ikke riktig state-blokk i Selected for dispatch")

text = text.replace(old_block, new_block, 1)

old_chip_block = """                        _infoChip('Score', score),
                        _infoChip('Type', commissionType),
"""

new_chip_block = """                        _infoChip('Score', score),
                        if (businessScore.isNotEmpty && businessScore != '-')
                          _infoChip('Business', businessScore),
                        _infoChip('Type', commissionType),
"""

if old_chip_block not in text:
    raise SystemExit("❌ Fant ikke riktig chip-blokk i Selected for dispatch")

text = text.replace(old_chip_block, new_chip_block, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn businessScore i Selected for dispatch, og kun der")
PY

flutter analyze
echo "✅ 852 ferdig"
