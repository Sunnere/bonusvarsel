#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_856.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

start_marker = """          const Text(
            'Selected for dispatch',
"""
end_marker = """          const SizedBox(height: 14),
          const Text(
            'Recent campaigns"""

start = text.find(start_marker)
if start == -1:
    raise SystemExit("❌ Fant ikke starten på 'Selected for dispatch'-seksjonen")

end = text.find(end_marker, start)
if end == -1:
    raise SystemExit("❌ Fant ikke slutten på 'Selected for dispatch'-seksjonen")

replacement = """          const Text(
            'Selected for dispatch',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Builder(
            builder: (_) {
              final selectedItems = _activatedNotifications.isNotEmpty
                  ? _activatedNotifications.take(3).toList()
                  : _recentCampaigns
                      .where((c) => c['shouldNotify'] == true)
                      .take(3)
                      .toList();

              if (selectedItems.isEmpty) {
                return const Text(
                  'Ingen dispatch-kandidater ennå.',
                  style: TextStyle(
                    color: _textSoft,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selectedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isWinner = index == 0;

                  final title = item['title']?.toString() ?? '-';
                  final rate = (item['rate'] ?? item['multiplier'] ?? '-').toString();
                  final score = item['score']?.toString() ?? '-';
                  final businessScore = item['businessScore']?.toString() ?? '-';
                  final priorityReason = item['priorityReason']?.toString() ?? '-';
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
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B),
                                  ),
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
                            if (businessScore.isNotEmpty && businessScore != '-')
                              _infoChip('Business', businessScore),
                            if (commissionType.isNotEmpty && commissionType != '-')
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
                        if (isWinner &&
                            priorityReason.isNotEmpty &&
                            priorityReason != '-') ...[
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
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

"""

text = text[:start] + replacement + text[end:]

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Gjorde Selected for dispatch stabil med fallback til recent campaigns")
PY

flutter analyze
echo "✅ 856 ferdig"
