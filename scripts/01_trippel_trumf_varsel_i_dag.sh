#!/bin/bash
# ============================================================================
# 01_trippel_trumf_varsel_i_dag.sh
#
# Formål: Endre Trippel Trumf-varselet PERMANENT slik at det sendes 2 dager
# før selve Trippel Trumf-dagen (kl 18:00), i stedet for 1 dag før som i dag.
# Effekt akkurat nå: varselet for 17. sept sendes 15. sept (i dag) kl 18:00
# i stedet for 16. sept. Gjelder også fremtidige datoer i listen (f.eks. 15. okt).
#
# VIKTIG - LES FØR DU KJØRER:
# Dette scriptet er testet mot en STAND-IN-fil som gjenskaper mønsteret vi
# vet finnes i api/server.js fra tidligere økter (TRIPPEL_TRUMF_PREDICTED_
# DATES_2026 + triggerHour = 18, "kvelden før"-logikk). Det er IKKE testet
# mot din ekte kildekode, fordi denne økten ikke har tilgang til Mac-en din.
#
# Kjør slik:
#   cd /Users/sunnerehelse/bonusvarsel
#   bash 01_trippel_trumf_varsel_i_dag.sh
#
# Scriptet:
#   1. Leter etter mønsteret "dayBefore.setDate(dayBefore.getDate() - 1)"
#      i api/server.js
#   2. Hvis funnet: kommenterer det ut og legger til en variant som bruker
#      SAMME dag som Trippel Trumf-datoen i stedet for dagen før
#   3. Hvis IKKE funnet: gjør INGENTING og forteller deg det, slik at vi kan
#      justere scriptet basert på din faktiske kode i stedet for å gjette
#
# ETTER KJØRING - OBLIGATORISK:
#   git diff api/server.js
# Sjekk at endringen faktisk traff riktig sted og gir mening. Ikke commit
# blindt. Hvis mønsteret ikke ble funnet, lim inn den relevante delen av
# api/server.js (Trippel Trumf-logikken) i chatten så lager jeg et presist
# script i stedet for et som gjetter.
# ============================================================================

set -euo pipefail

TARGET_FILE="api/server.js"

if [ ! -f "$TARGET_FILE" ]; then
  echo "❌ Fant ikke $TARGET_FILE i gjeldende mappe."
  echo "   Kjør scriptet fra roten av bonusvarsel-repoet:"
  echo "   cd /Users/sunnerehelse/bonusvarsel && bash scripts/01_trippel_trumf_varsel_i_dag.sh"
  exit 1
fi

if ! grep -q "getDate() - 1" "$TARGET_FILE"; then
  echo "⚠️  Fant ikke det forventede mønsteret (\"getDate() - 1\") i $TARGET_FILE."
  echo "   Gjør INGEN endring — koden stemmer sannsynligvis ikke med det vi husker fra tidligere økter."
  echo ""
  echo "   Neste steg: kjør dette og lim resultatet inn i chatten, så lager jeg et presist script:"
  echo "   grep -n \"TRIPPEL_TRUMF\\|dayBefore\\|triggerHour\" $TARGET_FILE"
  exit 2
fi

cp "$TARGET_FILE" "${TARGET_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "✅ Sikkerhetskopi laget: ${TARGET_FILE}.bak_$(date +%Y%m%d_%H%M%S)"

# Kommenter ut "dagen før"-linjen og legg til en tydelig markert erstatning
# som bruker samme dag i stedet for dagen før.
python3 - "$TARGET_FILE" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

old_pattern = re.compile(
    r"(const dayBefore = new Date\(trippelDate\);\s*\n\s*)dayBefore\.setDate\(dayBefore\.getDate\(\) - 1\);"
)

def replacement(m):
    return (
        m.group(1)
        + "// ENDRET 2026-09-15: varsel skal nå sendes I DAG (15. sept), altså\n"
        + "  // to dager før selve Trippel Trumf-dagen (17. sept), ikke én dag før.\n"
        + "  // Gammel linje bevart som kommentar for referanse:\n"
        + "  // dayBefore.setDate(dayBefore.getDate() - 1);\n"
        + "  dayBefore.setDate(dayBefore.getDate() - 2);"
    )

new_content, n = old_pattern.subn(replacement, content)

if n == 0:
    print("PATCH_FAILED_NO_MATCH")
    sys.exit(2)

with open(path, "w", encoding="utf-8") as f:
    f.write(new_content)

print(f"PATCH_OK matches={n}")
PYEOF

PATCH_STATUS=$?

if [ "$PATCH_STATUS" -ne 0 ]; then
  echo "❌ Patch feilet — gjenopprett fra backup om nødvendig."
  exit 2
fi

echo ""
echo "✅ Endring gjort i $TARGET_FILE"
echo ""
echo "NESTE STEG (viktig):"
echo "  1. git diff $TARGET_FILE   ← sjekk at endringen ser riktig ut"
echo "  2. Test lokalt eller på Railway før du stoler på den"
echo "  3. git add $TARGET_FILE && git commit -m \"Trippel Trumf-varsel: samme dag i stedet for kvelden før\""
echo "  4. git push"
echo ""
echo "Husk: Railway sin in-memory state nullstilles ved deploy — sjekk om"
echo "favoritter må registreres på nytt før du tester check-favorites."
