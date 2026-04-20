#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_839.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old_state = """              final shouldNotify = campaign['shouldNotify'] == true;
              final dispatchEligible = campaign['dispatchEligible'] == true;
              final reason = campaign['reason']?.toString() ?? '-';
              final commissionType = campaign['commissionType']?.toString() ?? '-';

              final isHighBonus = multiplierValue >= 2.0;
"""

new_state = """              final shouldNotify = campaign['shouldNotify'] == true;
              final dispatchEligible = campaign['dispatchEligible'] == true;
              final reason = campaign['reason']?.toString() ?? '-';
              final priorityReason = campaign['priorityReason']?.toString() ?? '-';
              final commissionType = campaign['commissionType']?.toString() ?? '-';

              final isHighBonus = multiplierValue >= 2.0;
"""

if old_state not in text:
    raise SystemExit("❌ Fant ikke campaign-state-blokken")
text = text.replace(old_state, new_state, 1)

old_reason = """                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
"""

new_reason = """                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
"""

if old_reason not in text:
    raise SystemExit("❌ Fant ikke reason-blokken")
text = text.replace(old_reason, new_reason, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Viser priorityReason i pipeline-UI")
PY

flutter analyze
echo "✅ 839 ferdig"
