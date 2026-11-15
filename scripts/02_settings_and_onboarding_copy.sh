#!/usr/bin/env bash
# 02_settings_and_onboarding_copy.sh
# 1) Legger tilbake engelsk linje på onboarding steg 2.
# 2) Fjerner SkyTeam og endrer "concierge-support" i Innstillinger (Elite-kort + hjelpetekst).
# Avbryter uten å skrive noe hvis en streng ikke finnes nøyaktig så mange ganger som forventet.
set -euo pipefail

ROOT="${ROOT:-$HOME/bonusvarsel}"
cd "$ROOT"
echo "🔧 Oppdaterer tekst i: $(pwd)"

python3 - <<'PY'
import os, re, pathlib, datetime, sys

root = pathlib.Path(os.getcwd())
ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

ONB = "lib/pages/onboarding_page.dart"
SET = "lib/pages/settings_page.dart"

EDITS = [
    # Engelsk linje tilbake på onboarding steg 2
    (ONB, "lit", "muligheter på ett sted.'",
                 r"muligheter på ett sted.\nWe show you where to earn the most — all in one place.'", 1),

    # Innstillinger: Elite-kort og hjelpetekst
    (SET, "rx", r"^[ \t]*_statusRow\('✅', 'SkyTeam-flyselskaper'\),\n", "", 1),
    (SET, "lit", "VIP-varsler, concierge-support.", "VIP-varsler, prioritert support.", 1),
    (SET, "lit", "VIP alerts, concierge support.", "VIP alerts, priority support.", 1),
]

texts, errors = {}, []
for f, *_ in EDITS:
    p = root / f
    if not p.exists():
        errors.append(f"Finner ikke fil: {f}")
    else:
        texts.setdefault(f, p.read_text(encoding="utf-8"))

for f, kind, old, new, expected in EDITS:
    if f not in texts:
        continue
    found = texts[f].count(old) if kind == "lit" else len(re.findall(old, texts[f], flags=re.M))
    if found != expected:
        errors.append(f"{f}: fant {found} treff for ({kind}) {old[:60]!r}, forventet {expected}")

if errors:
    print("❌ Avbrutt – ingen filer er endret:")
    for e in errors:
        print("  -", e)
    sys.exit(1)

for f, kind, old, new, expected in EDITS:
    if kind == "lit":
        texts[f] = texts[f].replace(old, new)
    else:
        texts[f] = re.sub(old, new, texts[f], flags=re.M)

for f in texts:
    p = root / f
    bak = p.with_name(p.name + f".bak_copy_{ts}")
    bak.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")
    p.write_text(texts[f], encoding="utf-8")
    print(f"✅ Oppdatert: {f}  (backup: {bak.name})")

print(f"✅ Ferdig – {len(EDITS)} endringer kontrollert og brukt.")
PY
