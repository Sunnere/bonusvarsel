#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_786.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()

old = """                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip('Source', '${_lastState?['source'] ?? '-'}'),
                      _infoChip(
                        'Scanned',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['scanned'] ?? '-'}',
                      ),
                      _infoChip(
                        'Queued',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['queued'] ?? '-'}',
                      ),
                      _infoChip(
                        'Dispatched',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['dispatched'] ?? '-'}',
                      ),
                      _infoChip('Simulation', '${_lastState?['id'] ?? '-'}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
"""

new = """                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip('Source', '${_lastState?['source'] ?? '-'}'),
                      _infoChip(
                        'Scanned',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['scanned'] ?? '-'}',
                      ),
                      _infoChip(
                        'Queued',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['queued'] ?? '-'}',
                      ),
                      _infoChip(
                        'Dispatched',
                        '${(_lastState?['pipeline'] as Map<String, dynamic>?)?['dispatched'] ?? '-'}',
                      ),
                      _infoChip('Simulation', '${_lastState?['id'] ?? '-'}'),
                      _infoChip(
                        'Last updated',
                        '${_lastState?['lastUpdated'] ?? '-'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Summary: ${_lastState?['summary'] ?? '-'}',
                    style: const TextStyle(
                      color: _textSoft,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
"""

if old not in text:
    raise SystemExit("❌ Fant ikke Live pipeline state-blokken i dev_pipeline_panel.dart")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ La inn last updated og summary i pipeline-panelet")
PY

flutter analyze
echo "✅ 786 ferdig"
