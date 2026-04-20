#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/ad_slot_card.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_911.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/ad_slot_card.dart")
text = p.read_text()
orig = text
changes = []

def rep(old, new, label):
    global text
    if old in text:
        text = text.replace(old, new)
        changes.append(label)

# Forsiktig lysning av vanlige mørke premium-farger
rep("0xFF0B1F4D", "0xFF163A70", "lysere hovedblå")
rep("0xFF0F172A", "0xFF1E2F4D", "mindre mørk navy")
rep("0xFF111827", "0xFF223552", "mindre tung mørk bakgrunn")

# Litt tydeligere border/overlay
rep("Colors.white.withValues(alpha: 0.08)", "Colors.white.withValues(alpha: 0.14)", "tydeligere border")
rep("Colors.white.withValues(alpha: 0.10)", "Colors.white.withValues(alpha: 0.16)", "tydeligere border 2")
rep("alpha: 0.15", "alpha: 0.22", "lysere alpha 1")
rep("alpha: 0.16", "alpha: 0.24", "lysere alpha 2")

# Litt tydeligere CTA hvis den finnes
rep("fontWeight: FontWeight.w600", "fontWeight: FontWeight.w700", "sterkere CTA-vekt")

if text == orig:
    raise SystemExit("❌ Fant ingen kjente annonsefarger å endre i ad_slot_card.dart")

p.write_text(text)
print("✅ Lysnet annonsekortet:")
for c in changes:
    print(" -", c)
PY

flutter analyze
echo "✅ 911 ferdig"
