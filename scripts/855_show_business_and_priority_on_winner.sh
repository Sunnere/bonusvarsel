#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_855.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old_state = """              final title = item['title']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';
"""

new_state = """              final title = item['title']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final businessScore = item['businessScore']?.toString() ?? '-';
              final priorityReason = item['priorityReason']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';
"""

if old_state not in text:
    raise SystemExit("❌ Fant ikke state-blokken i Selected for dispatch")

text = text.replace(old_state, new_state, 1)

old_chip_block = """                        _infoChip('Score', score),
                        _infoChip('Type', commissionType),
"""

new_chip_block = """                        _infoChip('Score', score),
                        if (businessScore.isNotEmpty && businessScore != '-')
                          _infoChip('Business', businessScore),
                        _infoChip('Type', commissionType),
"""

if old_chip_block not in text:
    raise SystemExit("❌ Fant ikke chip-blokken i Selected for dispatch")

text = text.replace(old_chip_block, new_chip_block, 1)

old_reason_block = """                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
"""

new_reason_block = """                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isWinner && priorityReason.isNotEmpty && priorityReason != '-') ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                              ),
                            ),
                            child: const Text(
                              'Prioritet',
                              style: TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            priorityReason,
                            style: const TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
"""

if old_reason_block not in text:
    raise SystemExit("❌ Fant ikke reason-blokken i Selected for dispatch")

text = text.replace(old_reason_block, new_reason_block, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Viser businessScore og priorityReason på WINNER i Selected for dispatch")
PY

flutter analyze
echo "✅ 855 ferdig"
