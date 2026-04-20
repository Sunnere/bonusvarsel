#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_897.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/premium_page.dart")
text = p.read_text()
orig = text

changes = []

def replace_once(old, new, label):
    global text, changes
    if old in text:
        text = text.replace(old, new, 1)
        changes.append(label)

def replace_all(old, new, label):
    global text, changes
    if old in text:
        text = text.replace(old, new)
        changes.append(label)

# 1) Elite-label mer luksus
replace_all("'Best verdi'", "'Elite valg'", "badge: Best verdi -> Elite valg")
replace_all('"Best verdi"', '"Elite valg"', 'badge: "Best verdi" -> "Elite valg"')

# 2) Rydd vekk "Valgt nå" hvis det ligger som løs tekst
replace_all("'Valgt nå'", "''", "fjernet tekst: Valgt nå")
replace_all('"Valgt nå"', '""', 'fjernet tekst: "Valgt nå"')

# 3) Hvis fila har tydelig sticky-widget, nøytraliser den
sticky_patterns = [
    (
        r"(Widget\s+_buildStickyUpgradeBar\s*\([^\)]*\)\s*\{)([\s\S]*?)(\n\})",
        r"\1\n    return const SizedBox.shrink();\3",
        "nøytraliserte _buildStickyUpgradeBar()",
    ),
    (
        r"(Widget\s+_stickyUpgradeBar\s*\([^\)]*\)\s*\{)([\s\S]*?)(\n\})",
        r"\1\n    return const SizedBox.shrink();\3",
        "nøytraliserte _stickyUpgradeBar()",
    ),
]

for pat, repl, label in sticky_patterns:
    new_text = re.sub(pat, repl, text, count=1, flags=re.MULTILINE)
    if new_text != text:
        text = new_text
        changes.append(label)

# 4) Hvis bool/flag for sticky finnes, slå den av
flag_replacements = [
    (r"bool\s+_showStickyUpgrade\s*=\s*true\s*;", "bool _showStickyUpgrade = false;", "satte _showStickyUpgrade=false"),
    (r"final\s+bool\s+_showStickyUpgrade\s*=\s*true\s*;", "final bool _showStickyUpgrade = false;", "satte final _showStickyUpgrade=false"),
]

for pat, repl, label in flag_replacements:
    new_text = re.sub(pat, repl, text, count=1)
    if new_text != text:
        text = new_text
        changes.append(label)

# 5) Gjør Elite visuelt litt tydeligere via safe tekstjusteringer
replace_all("Start Elite", "Velg Elite", "knapp: Start Elite -> Velg Elite")
replace_all("Start Premium", "Velg Premium", "knapp: Start Premium -> Velg Premium")

# 6) Litt mer eksklusiv tekst på Elite hvis den finnes
replace_all("Flere programmer (SAS + SkyTeam + Trumf m.fl.)",
            "Flere programmer (SAS + SkyTeam + Trumf m.fl.)",
            "ingen-op endring for stabilitet")

if text == orig:
    raise SystemExit("❌ Ingen trygge Premium/Elite-endringer ble funnet")

p.write_text(text)
print("✅ Gjorde følgende endringer:")
for c in changes:
    print(" -", c)
PY

flutter analyze
echo "✅ 897 ferdig"
