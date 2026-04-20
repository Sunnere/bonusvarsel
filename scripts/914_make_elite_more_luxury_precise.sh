#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_914.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/premium_page.dart")
text = p.read_text()
orig = text
changes = []

def rep(old, new, label):
    global text
    if old in text:
        text = text.replace(old, new)
        changes.append(label)

# Elite-badge mer eksklusiv
rep("'Elite valg'", "'Mest eksklusiv'", "Elite badge-tekst")
rep('"Elite valg"', '"Mest eksklusiv"', "Elite badge-tekst")

# Gull/champagne litt rikere
rep("0xFFE7C977", "0xFFF0D48A", "champagne-gull løftet")
rep("0xFFD4AF37", "0xFFE5C66B", "gull løftet")

# Dypere luksus-bakgrunn hvis brukt
rep("0xFF0F172A", "0xFF0B1220", "Elite mørkere bakgrunn")
rep("0xFF121826", "0xFF0A1120", "Elite mørkere bakgrunn 2")
rep("0xFF1E3A8A", "0xFF1D3B73", "Premium beholdt dyp blå")
rep("0xFF356FE0", "0xFF2E63C9", "Premium litt dypere blå")

# Knappetekster litt mer eksklusive
rep("Velg Elite", "Elite", "kortere Elite-knapp")
rep("Velg Premium", "Premium", "kortere Premium-knapp")

# Litt tydeligere kontrast på mørk tekst på gull-knapper
rep("foregroundColor: Colors.black", "foregroundColor: const Color(0xFF111111)", "mykere mørk tekst på gull")

if text == orig:
    raise SystemExit("❌ Fant ingen kjente Elite-farger/tekster å endre")

p.write_text(text)
print("✅ Elite gjort mer luksuriøs:")
for c in changes:
    print(" -", c)
PY

flutter analyze
echo "✅ 914 ferdig"
