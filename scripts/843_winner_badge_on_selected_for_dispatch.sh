#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_843.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old = """            ..._recentCampaigns
                .where((c) => c['shouldNotify'] == true)
                .take(3)
                .map((campaign) {
              final title = campaign['title']?.toString() ?? '-';
              final multiplier = campaign['multiplier']?.toString() ?? '-';
              final score = campaign['score']?.toString() ?? '-';
              final reason = campaign['reason']?.toString() ?? '-';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1)),
                ),
                child: Column(
"""

new = """            ..._recentCampaigns
                .where((c) => c['shouldNotify'] == true)
                .take(3)
                .toList()
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final campaign = entry.value;
              final isWinner = index == 0;

              final title = campaign['title']?.toString() ?? '-';
              final multiplier = campaign['multiplier']?.toString() ?? '-';
              final score = campaign['score']?.toString() ?? '-';
              final reason = campaign['reason']?.toString() ?? '-';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isWinner
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWinner
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF6366F1),
                  ),
                ),
                child: Column(
"""

if old not in text:
    raise SystemExit("❌ Fant ikke Selected for dispatch-lista")
text = text.replace(old, new, 1)

old2 = """                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${multiplier}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _infoChip('Score', score),
                      ],
                    ),
"""

new2 = """                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (isWinner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: const Text(
                              '🏆 WINNER',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${multiplier}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _infoChip('Score', score),
                      ],
                    ),
"""

if old2 not in text:
    raise SystemExit("❌ Fant ikke title/multiplier-blokken i Selected for dispatch")
text = text.replace(old2, new2, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn WINNER på første kort i Selected for dispatch")
PY

flutter analyze
echo "✅ 843 ferdig"
