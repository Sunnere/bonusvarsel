#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_778_3.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

old = """    final pipeline = health?['pipeline'] is Map<String, dynamic>
        ? health?['pipeline'] as Map<String, dynamic>
        : (health?['pipeline'] is Map
            ? Map<String, dynamic>.from(health?['pipeline'] as Map)
            : null);
"""

new = """    final rawPipeline = health?['pipeline'];
    final Map<String, dynamic>? pipeline =
        rawPipeline is Map ? Map<String, dynamic>.from(rawPipeline) : null;
"""

if old not in text:
    raise SystemExit("❌ Fant ikke forventet pipeline-cast-blokk")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Fikset pipeline-cast i system health")
PY

flutter analyze
echo "✅ 778.3 ferdig"
