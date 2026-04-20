#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# 1) Fjern ødelagt løsblokk mellom ALERT_HISTORY_START og neste tydelige widget/metode-område
start_marker = "// AI_ANCHOR: DEV_HUB_ALERT_HISTORY_START"
end_marker = "Widget _systemHealthPanel()"

if start_marker in text and end_marker in text:
    start = text.index(start_marker)
    end = text.index(end_marker)
    replacement = """// AI_ANCHOR: DEV_HUB_ALERT_HISTORY_START
  Widget _alertSimulationHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alert simulation history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (_alertSimulationHistory.isEmpty)
            const Text(
              'Ingen simuleringer ennå.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            )
          else
            Column(
              children: List.generate(_alertSimulationHistory.length, (index) {
                final entry = _alertSimulationHistory[index];
                final offer = entry['offer'] as Map<String, dynamic>?;
                final evaluation = entry['evaluation'] as Map<String, dynamic>?;

                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    bottom: index == _alertSimulationHistory.length - 1 ? 0 : 10,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black.withValues(alpha: 0.03),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulering #${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _metricChip('Rate', '${offer?['rateText'] ?? offer?['rate'] ?? '-'}'),
                          _metricChip('Level', '${offer?['level'] ?? '-'}'),
                          _metricChip('Campaign', '${offer?['campaign'] ?? '-'}'),
                          _metricChip('Score', '${evaluation?['score'] ?? '-'}'),
                          _metricChip('Momentum', '${evaluation?['momentum'] ?? '-'}'),
                          _metricChip('Timing', '${evaluation?['timing'] ?? '-'}'),
                          _metricChip('Notify', '${evaluation?['shouldNotify'] ?? '-'}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${(evaluation?['reason'] ?? '-').toString()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Simulated at: ${entry['simulatedAt'] ?? '-'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

"""
    text = text[:start] + replacement + text[end:]

# 2) Sørg for at widgeten faktisk rendres i build
needle = "          // AI_ANCHOR: DEV_HUB_BUILD_ALERT_HISTORY\n"
insert = """          // AI_ANCHOR: DEV_HUB_BUILD_ALERT_HISTORY
          _alertSimulationHistoryCard(),
          const SizedBox(height: 16),
"""
if needle in text and "_alertSimulationHistoryCard()," not in text[text.index(needle):text.index(needle)+200]:
    text = text.replace(needle, insert, 1)

p.write_text(text)
print("✅ Gjenopprettet alert simulation history card")
PY

flutter analyze
echo "✅ 762 ferdig"
