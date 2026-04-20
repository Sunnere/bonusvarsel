#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_831.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()
original = text

candidates = [
("""child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [""",
 """child: ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: ["""),
("""child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [""",
 """child: ListView(
          padding: const EdgeInsets.only(bottom: 48),
          children: ["""),
]

changed = False
for old, new in candidates:
    if old in text:
        text = text.replace(old, new, 1)
        changed = True
        break

if not changed:
    raise SystemExit("❌ Fant ikke trygg Column-wrapper å bytte til ListView")

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Byttet Dev Hub body-wrapper fra Column til ListView")
PY

flutter analyze
echo "✅ 831 ferdig"
