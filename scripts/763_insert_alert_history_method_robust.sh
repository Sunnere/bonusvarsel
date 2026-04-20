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

if "Widget _alertSimulationHistoryCard()" in text:
    print("✅ _alertSimulationHistoryCard finnes allerede")
    raise SystemExit(0)

method = """
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

# ensure build actually references the widget
needle = "          // AI_ANCHOR: DEV_HUB_BUILD_ALERT_HISTORY\n"
insert = """          // AI_ANCHOR: DEV_HUB_BUILD_ALERT_HISTORY
          _alertSimulationHistoryCard(),
          const SizedBox(height: 16),
"""
if needle in text and "_alertSimulationHistoryCard()," not in text[text.index(needle):text.index(needle)+200]:
    text = text.replace(needle, insert, 1)

# Insert before _systemHealthPanel if present
marker = "  Widget _systemHealthPanel()"
if marker in text:
    text = text.replace(marker, method + marker, 1)
else:
    # fallback: insert before final closing brace of state class
    class_pat = re.search(r"class _BonusvarselDevHubPageState extends State<BonusvarselDevHubPage> \{", text)
    if not class_pat:
        raise SystemExit("❌ Fant ikke state-klassen")
    start = class_pat.end() - 1
    depth = 0
    end = None
    for i in range(start, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is None:
        raise SystemExit("❌ Fant ikke slutten på state-klassen")
    text = text[:end] + "\n" + method + text[end:]

p.write_text(text)
print("✅ La inn _alertSimulationHistoryCard robust")
PY

flutter analyze
echo "✅ 763 ferdig"
