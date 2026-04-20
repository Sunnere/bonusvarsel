#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_880.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/premium_page.dart")
text = p.read_text()
orig = text

# 1) Fjern flytende oppgraderingsbar nederst hvis den finnes
patterns = [
    r"\n\s*if\s*\(_showStickyUpgrade[\s\S]*?\n\s*\],\n\s*\),\n",
    r"\n\s*Positioned\([\s\S]*?Oppgrader[\s\S]*?\n\s*\),\n",
    r"\n\s*_buildStickyUpgradeBar\([^\n]*\),\n",
]

for pat in patterns:
    text = re.sub(pat, "\n", text, flags=re.MULTILINE)

# 2) Elite: sterkere luksusfarger
replacements = [
    ("const Color(0xFFD4AF37)", "const Color(0xFFE0C46C)"),  # litt mykere gull
    ("const Color(0xFF2F80ED)", "const Color(0xFF356FE0)"),  # premium blå litt dypere
    ("Best verdi", "Elite"),
]

for old, new in replacements:
    text = text.replace(old, new)

# 3) Hvis Elite-badge har teksten Best verdi, gi mer luksuriøs label
text = text.replace("'Best verdi'", "'Elite valg'")
text = text.replace('"Best verdi"', '"Elite valg"')

# 4) Legg inn elite-spesifikke farger hvis eksisterende koder finnes
text = text.replace(
    "color: const Color(0xFF0B1F4D),",
    "color: const Color(0xFF121826),",
)
text = text.replace(
    "border: Border.all(color: const Color(0xFFD4AF37)),",
    "border: Border.all(color: const Color(0xFFE0C46C)),",
)

# 5) Fjern teksten 'Valgt nå' hvis den ligger igjen som skaper rot
text = text.replace("Valgt nå", "")

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Premium-side ryddet: sticky upgrade forsøkt fjernet + Elite luksusjustert")
PY

flutter analyze
echo "✅ 880 ferdig"
