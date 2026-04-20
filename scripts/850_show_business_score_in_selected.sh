#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_850.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old_state = """              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';
"""

new_state = """              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final businessScore = item['businessScore']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';
"""

if old_state not in text:
    raise SystemExit("❌ Fant ikke state-blokken i Selected for dispatch")

text = text.replace(old_state, new_state, 1)

old_chip = """                        _infoChip('Score', score),
                        if (commissionType.isNotEmpty && commissionType != '-')
                          _infoChip('Type', commissionType),"""

new_chip = """                        _infoChip('Score', score),
                        if (businessScore.isNotEmpty && businessScore != '-')
                          _infoChip('Business', businessScore),
                        if (commissionType.isNotEmpty && commissionType != '-')
                          _infoChip('Type', commissionType),"""

if old_chip not in text:
    raise SystemExit("❌ Fant ikke chip-blokken i Selected for dispatch")

text = text.replace(old_chip, new_chip, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Viser businessScore i Selected for dispatch")
PY

flutter analyze
echo "✅ 850 ferdig"
