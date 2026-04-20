#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_847.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

replacements = [
    ("'Recent campaigns'", "'Recent campaigns (evaluated)'"),
    ("'Ingen recent campaigns ennå.'", "'Ingen evaluerte kampanjer ennå.'"),
]

changed = 0
for old, new in replacements:
    if old in text:
        text = text.replace(old, new, 1)
        changed += 1

if changed == 0:
    raise SystemExit("❌ Fant ingen tekst å endre")

p.write_text(text)
print(f"✅ Gjorde {changed} trygg(e) tekstendring(er) i Recent campaigns")
PY

flutter analyze
echo "✅ 847 ferdig"
