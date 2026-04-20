#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_779.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# 1) Legg inn metoden hvis den ikke finnes
if "Widget _decisionInsightCard()" not in text:
    marker = "  Widget _alertSimulationHistoryCard() {"
    method = """
  Widget _decisionInsightCard() {
    final result = _alertSimulationResult;
    final offer = result?['offer'] is Map
        ? Map<String, dynamic>.from(result?['offer'] as Map)
        : <String, dynamic>{};
    final evaluation = result?['evaluation'] is Map
        ? Map<String, dynamic>.from(result?['evaluation'] as Map)
        : <String, dynamic>{};

    final score = evaluation['score']?.toString() ?? '-';
    final threshold = evaluation['threshold']?.toString() ?? '-';
    final momentum = evaluation['momentum']?.toString() ?? '-';
    final timing = evaluation['timing']?.toString() ?? '-';
    final shouldNotify = evaluation['shouldNotify'];
    final reason = evaluation['reason']?.toString() ?? '-';
    final rateText = offer['rateText']?.toString() ??
        (offer['rate'] != null ? '${offer['rate']}x' : '-');
    final level = offer['level']?.toString() ?? '-';
    final campaign = offer['campaign']?.toString() ?? '-';

    final decisionText = shouldNotify == true
        ? 'SEND'
        : shouldNotify == false
            ? 'SKIP'
            : '-';

    final decisionColor = shouldNotify == true
        ? const Color(0xFF047857)
        : shouldNotify == false
            ? const Color(0xFFB91C1C)
            : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF111827),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Decision insight',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (result == null)
            const Text(
              'Ingen alert simulation kjørt ennå.',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('Rate', rateText),
                _metricChip('Level', level),
                _metricChip('Campaign', campaign),
                _metricChip(
                  'Score',
                  threshold != '-' ? '$score / $threshold' : score,
                ),
                _metricChip('Momentum', momentum),
                _metricChip('Timing', timing),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: decisionColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: decisionColor.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Text(
                    'Decision: $decisionText',
                    style: TextStyle(
                      color: decisionColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF1F2937),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Reason: $reason',
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Simulated at: ${result['simulatedAt'] ?? '-'}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

"""
    if marker not in text:
        raise SystemExit("❌ Fant ikke anker for _decisionInsightCard()")
    text = text.replace(marker, method + marker, 1)

# 2) Koble inn i build hvis ikke allerede der
build_anchor = "          // AI_ANCHOR: DEV_HUB_BUILD_ALERT_HISTORY\n"
insert = """          const SizedBox(height: 16),
          _decisionInsightCard(),
          const SizedBox(height: 16),
          // AI_ANCHOR: DEV_HUB_BUILD_ALERT_HISTORY
"""
if build_anchor in text and "_decisionInsightCard()," not in text:
    text = text.replace(build_anchor, insert, 1)

p.write_text(text)
print("✅ La inn Decision insight-kort i Dev Hub")
PY

flutter analyze
echo "✅ 779 ferdig"
