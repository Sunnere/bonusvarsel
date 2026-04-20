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

pattern = re.compile(
    r"""
          Container\(
            \s*width:\ double\.infinity,
            \s*padding:\ const\ EdgeInsets\.all\(16\),
            \s*decoration:\ BoxDecoration\(
              \s*borderRadius:\ BorderRadius\.circular\(16\),
              \s*color:\ Colors\.white,
              \s*border:\ Border\.all\(color:\ Colors\.black12\),
            \),
            \s*child:\ const\ Text\('Alert\ history\ midlertidig\ skjult\ lokalt\.'\),
          \),
          \s*const\ SizedBox\(height:\ 16\),
""",
    re.VERBOSE,
)

new_text, count = pattern.subn("", text, count=1)

if count != 1:
    raise SystemExit("❌ Fant ikke alert history-placeholderen")

p.write_text(new_text)
print("✅ Fjernet alert history-placeholder")
PY

flutter analyze
echo "✅ 764 ferdig"
