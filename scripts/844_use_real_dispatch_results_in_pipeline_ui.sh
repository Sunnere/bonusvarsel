#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_844.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old = """          if (_recentCampaigns.isEmpty)
            const Text(
              'Ingen kandidater valgt.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._recentCampaigns
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
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
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
"""

new = """          if (_activatedNotifications.isEmpty)
            const Text(
              'Ingen faktiske dispatch-resultater ennå.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ..._activatedNotifications
                .take(3)
                .toList()
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isWinner = index == 0;

              final title = item['title']?.toString() ?? '-';
              final rate = item['rate']?.toString() ?? '-';
              final score = item['score']?.toString() ?? '-';
              final reason = item['reason']?.toString() ?? '-';
              final commissionType = item['commissionType']?.toString() ?? '-';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                            '${rate}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _infoChip('Score', score),
                        _infoChip('Type', commissionType),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke eksisterende Selected for dispatch-blokk")

text = text.replace(old, new, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Selected for dispatch bruker nå ekte _activatedNotifications")
PY

flutter analyze
echo "✅ 844 ferdig"
