#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_787.$(date +%s)"
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
"""

new = """                  Builder(
                    builder: (_) {
                      final pipeline =
                          _lastState?['pipeline'] is Map<String, dynamic>
                              ? _lastState?['pipeline'] as Map<String, dynamic>
                              : (_lastState?['pipeline'] is Map
                                  ? Map<String, dynamic>.from(
                                      _lastState?['pipeline'] as Map,
                                    )
                                  : <String, dynamic>{});

                      final source =
                          (_lastState?['source'] ?? pipeline['source'] ?? '-')
                              .toString();
                      final scanned = (pipeline['scanned'] ?? '-').toString();
                      final queued = (pipeline['queued'] ?? '-').toString();
                      final dispatched =
                          (pipeline['dispatched'] ?? '-').toString();
                      final simulationId =
                          (_lastState?['id'] ??
                                  pipeline['lastSimulationId'] ??
                                  '-')
                              .toString();
                      final lastUpdated =
                          (_lastState?['lastUpdated'] ??
                                  pipeline['lastUpdated'] ??
                                  '-')
                              .toString();
                      final summary =
                          (_lastState?['summary'] ??
                                  pipeline['summary'] ??
                                  '-')
                              .toString();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoChip('Source', source),
                              _infoChip('Scanned', scanned),
                              _infoChip('Queued', queued),
                              _infoChip('Dispatched', dispatched),
                              _infoChip('Simulation', simulationId),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pipeline meta',
                                  style: TextStyle(
                                    color: _text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Last updated: $lastUpdated',
                                  style: const TextStyle(
                                    color: _textSoft,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Summary: $summary',
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
                      );
                    },
                  ),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke forventet Live pipeline state-blokk å erstatte")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Gjorde pipeline-meta tydelig med fallback-felt")
PY

flutter analyze
echo "✅ 787 ferdig"
