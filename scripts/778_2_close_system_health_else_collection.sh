#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_778_2.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

old = """            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('API', apiUp ? 'up' : 'down'),
                _metricChip('Version', version),
                _metricChip('Dev routes', devRoutesEnabled),
                _metricChip('Pipeline source', source),
                _metricChip('Feed count', '$feedCount'),
                _metricChip('Notifications', '$notificationCount'),
                _metricChip('Last sim', lastSimulationId),
                _metricChip(
                  'Loaded at',
                  _systemHealth?['loadedAt']?.toString() ?? '-',
                ),
              ],
            ),
"""

new = """            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('API', apiUp ? 'up' : 'down'),
                _metricChip('Version', version),
                _metricChip('Dev routes', devRoutesEnabled),
                _metricChip('Pipeline source', source),
                _metricChip('Feed count', '$feedCount'),
                _metricChip('Notifications', '$notificationCount'),
                _metricChip('Last sim', lastSimulationId),
                _metricChip(
                  'Loaded at',
                  _systemHealth?['loadedAt']?.toString() ?? '-',
                ),
              ],
            ),
          ],
"""

if old not in text:
    raise SystemExit("❌ Fant ikke forventet Wrap-blokk i system health")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Lukket else ...[] korrekt i system health")
PY

flutter analyze
echo "✅ 778.2 ferdig"
