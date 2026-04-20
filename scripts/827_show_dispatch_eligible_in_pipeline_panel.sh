#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_827.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

old = """              final shouldNotify = campaign['shouldNotify'] == true;
              final reason = campaign['reason']?.toString() ?? '-';

              final isHighBonus = multiplierValue >= 2.0;

              return Container(
"""

new = """              final shouldNotify = campaign['shouldNotify'] == true;
              final dispatchEligible = campaign['dispatchEligible'] == true;
              final reason = campaign['reason']?.toString() ?? '-';
              final commissionType = campaign['commissionType']?.toString() ?? '-';

              final isHighBonus = multiplierValue >= 2.0;

              return Container(
"""

if old not in text:
    raise SystemExit("❌ Fant ikke campaign-state-blokken")

text = text.replace(old, new, 1)

old2 = """                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: shouldNotify
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: shouldNotify
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            shouldNotify ? 'SEND' : 'SKIP',
                            style: TextStyle(
                              color: shouldNotify
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
"""

new2 = """                        if (dispatchEligible)
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
                              'Klar for dispatch',
                              style: TextStyle(
                                color: Color(0xFF1D4ED8),
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
                            color: shouldNotify
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: shouldNotify
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            shouldNotify ? 'SEND' : 'SKIP',
                            style: TextStyle(
                              color: shouldNotify
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
"""

if old2 not in text:
    raise SystemExit("❌ Fant ikke SEND/SKIP-badgen")

text = text.replace(old2, new2, 1)

old3 = """                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip('Multiplier', multiplier),
                        _infoChip('Score', score),
                      ],
                    ),
"""

new3 = """                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip('Multiplier', multiplier),
                        _infoChip('Score', score),
                        _infoChip('Type', commissionType),
                      ],
                    ),
"""

if old3 not in text:
    raise SystemExit("❌ Fant ikke infoChip-blokken")

text = text.replace(old3, new3, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Viser dispatchEligible og commissionType i pipeline-panelet")
PY

flutter analyze
echo "✅ 827 ferdig"
