#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_901.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

changes = []

def replace(old, new, label):
    global text
    if old in text:
        text = text.replace(old, new)
        changes.append(label)

# 1) Reduser padding i hero container
replace(
    "padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),",
    "padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),",
    "mindre padding"
)

# 2) Reduser outer padding
replace(
    "padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),",
    "padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),",
    "mindre outer spacing"
)

# 3) Reduser spacing mellom elementer
replace("const SizedBox(height: 12),", "const SizedBox(height: 8),", "spacing 12→8")
replace("const SizedBox(height: 10),", "const SizedBox(height: 6),", "spacing 10→6")
replace("const SizedBox(height: 6),", "const SizedBox(height: 4),", "spacing 6→4")

# 4) Litt mindre font på subtitle (trygg justering)
text = re.sub(
    r"(textTheme\.bodyMedium\?\.\w+With\(\s*[^)]*fontWeight: FontWeight\.w700,)",
    r"\1",
    text
)

# 5) Reduser border radius litt (mindre "plakat")
replace(
    "borderRadius: BorderRadius.circular(18),",
    "borderRadius: BorderRadius.circular(14),",
    "mindre radius"
)

if text == orig:
    raise SystemExit("❌ Fant ingen hero-endringer")

p.write_text(text)

print("✅ Hero redusert:")
for c in changes:
    print(" -", c)
PY

flutter analyze
echo "✅ 901 ferdig"
