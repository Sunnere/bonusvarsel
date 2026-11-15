#!/usr/bin/env bash
# 01_update_app_copy.sh
# Oppdaterer norsk app-tekst i Bonusvarsel (onboarding, "Få mer ut av bonusen"-arket,
# Elite-kort og Elite-fordeler). Avbryter uten å skrive noe hvis en streng ikke
# finnes nøyaktig så mange ganger som forventet. Lager .bak_copy_<tid>-kopi først.
set -euo pipefail

ROOT="${ROOT:-$HOME/bonusvarsel}"
cd "$ROOT"
echo "🔧 Oppdaterer tekst i: $(pwd)"

python3 - <<'PY'
import os, re, pathlib, datetime, sys

root = pathlib.Path(os.getcwd())
ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

ONB  = "lib/pages/onboarding_page.dart"
PAY  = "lib/widgets/premium_paywall_sheet.dart"
PREM = "lib/pages/premium_page.dart"
TRV  = "lib/pages/travel_page.dart"

# (fil, type, gammel, ny, forventet antall)
# type: "lit" = ordrett tekst, "rx" = regulært uttrykk (fjerner en hel linje)
EDITS = [
    # Onboarding steg 2
    (ONB, "lit", r"\nWe show you where to earn the most — all in one place.", "", 1),
    (ONB, "lit", "SAS + Trumf + kort + kampanjer", "SAS + Spenn + Trumf + kort + kampanjer", 1),

    # "Få mer ut av bonusen"-arket
    (PAY, "lit", "Du kan gå glipp av bedre rate", "Se hva som faktisk lønner seg før du handler.", 1),
    (PAY, "lit", "Typisk +1 500–4 000 poeng i måneden", "Estimert 1 500–4 000 poeng i måneden", 1),
    (PAY, "lit", "Få høyere bonusrate", "Se bonusrate per butikk før du handler", 1),
    (PAY, "lit", "Opptil 8 000+ poeng i måneden", "Estimert opptil 8 000 poeng i måneden", 1),
    (PAY, "lit", "Flere programmer og prioriterte valg", "Alle poengprogrammer, inkl. Avios og Flying Blue når de lanseres", 1),
    (PAY, "rx", r"^[ \t]*'Enda sterkere verdi og maks synlighet',\n", "", 1),

    # Elite-medlem-kortet (Premium-siden)
    (PREM, "lit", "Du har tilgang til alle funksjoner inkludert SkyTeam, 10 favoritter og VIP-varsler.",
                  "Du har tilgang til alle funksjoner inkludert 10 favoritter og VIP-varsler.", 1),
    (PREM, "rx", r"^[ \t]*'✅ SkyTeam-flyselskaper \(Air France, KLM, Delta\)',\n", "", 1),
    (PREM, "lit", "'✅ VIP-varsler og concierge-support'", "'✅ VIP-varsler og prioritert support'", 1),
    (PREM, "lit", "Få 10 favoritter, SkyTeam-bonus, VIP-varsler og concierge-support.",
                  "Få 10 favoritter, VIP-varsler og prioritert support.", 1),
    (PREM, "lit", "Opptil 8 000+ poeng/mnd", "Estimert opptil 8 000 poeng/mnd", 1),

    # Elite-fordeler på Reise-fanen
    (TRV, "lit", "Air France, KLM, Delta og 16 andre", "Air France, KLM, Delta og flere", 1),
    (TRV, "lit", "Bruk EuroBonus-poeng på Air France", "Se SkyTeam-partnere i appen", 1),
    (TRV, "rx", r"^[ \t]*'• SkyTeam-flyselskaper \(Air France, KLM, Delta\)\\n'[,]?\n", "", 1),
    (TRV, "lit", "VIP-varsler og concierge-support", "VIP-varsler og prioritert support", 1),
]

# 1) Les alle filer og kontroller antall treff før noe skrives
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
    if kind == "lit":
        found = texts[f].count(old)
    else:
        found = len(re.findall(old, texts[f], flags=re.M))
    if found != expected:
        errors.append(f"{f}: fant {found} treff for ({kind}) {old[:60]!r}, forventet {expected}")

if errors:
    print("❌ Avbrutt – ingen filer er endret:")
    for e in errors:
        print("  -", e)
    sys.exit(1)

# 2) Bruk alle endringer i minnet
for f, kind, old, new, expected in EDITS:
    if kind == "lit":
        texts[f] = texts[f].replace(old, new)
    else:
        texts[f] = re.sub(old, new, texts[f], flags=re.M)

# 3) Lag backup og skriv filene
for f in texts:
    p = root / f
    bak = p.with_name(p.name + f".bak_copy_{ts}")
    bak.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")
    p.write_text(texts[f], encoding="utf-8")
    print(f"✅ Oppdatert: {f}  (backup: {bak.name})")

print(f"✅ Ferdig – {len(EDITS)} endringer kontrollert og brukt.")
PY
