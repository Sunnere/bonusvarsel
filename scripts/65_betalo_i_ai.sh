# 65: Legger Betalo inn i AI-slagplanen og AI-chatten (ai_service.dart).
#  - Slagplan (punkt 4): kort tips om Betalo for brukere med SAS Amex som vil nå Companion Ticket
#  - Nøkkelstrategier i chatten: ny linje om Betalo (Bill Kill-linjen står uendret)
# Formuleringene er forsiktige: kan bidra til, dersom betalingen kvalifiserer, ingen garanti, ingen fast gebyrsats.
# Kjør fra Terminal:
#   bash ~/bonusvarsel/scripts/65_betalo_i_ai.sh
# Test-miljø: BV_REPO=/sti/til/kopi bash scripts/65_betalo_i_ai.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
cd "$REPO"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/65_${TS}"
mkdir -p "$BACKUP"

python3 - "$BACKUP" <<'PYEOF'
import sys, os, shutil
backup = sys.argv[1]
path = "lib/services/ai_service.dart"

ANCHOR_CHAT = "- Billkill.no: betal fakturaer med kort og tjen poeng\n"
LINE_CHAT = (
    "- Betalo (betalo.no): lar deg betale enkelte regninger med Amex-kort. Dersom betalingen kvalifiserer for "
    "kortopptjening, kan det bidra til å nå forbruksgrensen for Companion Ticket raskere. Gebyr og vilkår gjelder "
    "(sjekk gjeldende sats hos Betalo), og Amex kan bare brukes til private betalinger. Aldri garanter poeng. "
    "Nevn Betalo kort når brukeren har SAS Amex og vil samle mer forbruk. Vis til bonusvarsel.no/betalo for mer info.\n"
)

ANCHOR_PLAN = "Anbefalt strategi (companion ticket, bruk poeng på fly vs hotell osv.)"
LINE_PLAN = (
    "\n   Har brukeren SAS Amex og mål om Companion Ticket: si kort at det kan gå raskere å nå forbruksgrensen dersom "
    "faste regninger betales med Amex via Betalo (dersom betalingen kvalifiserer, gebyr og vilkår gjelder). "
    "Mer info på bonusvarsel.no/betalo. Ikke garanter poeng."
)

if not os.path.isfile(path):
    raise SystemExit("FEIL: finner ikke %s. Ingen filer er endret." % path)
with open(path, encoding="utf-8") as fh:
    src = fh.read()

if "Betalo (betalo.no)" in src:
    print("Betalo ligger allerede i ai_service.dart. Ingenting å gjøre.")
    raise SystemExit(0)

for label, anchor in (("chat-linjen", ANCHOR_CHAT), ("slagplan-punkt 4", ANCHOR_PLAN)):
    n = src.count(anchor)
    if not n == 1:
        raise SystemExit("FEIL: forventet 1 treff for %s, fant %d. Ingen filer er endret." % (label, n))

for txt in (LINE_CHAT, LINE_PLAN):
    if "$" in txt or "'''" in txt:
        raise SystemExit("FEIL: ugyldig tegn i tekst som skal inn i Dart-strengen. Ingen filer er endret.")

new = src.replace(ANCHOR_CHAT, ANCHOR_CHAT + LINE_CHAT, 1)
new = new.replace(ANCHOR_PLAN, ANCHOR_PLAN + LINE_PLAN, 1)

dest = os.path.join(backup, path)
os.makedirs(os.path.dirname(dest), exist_ok=True)
shutil.copy2(path, dest)
with open(path, "w", encoding="utf-8") as fh:
    fh.write(new)
print("Endret: " + path)
PYEOF

echo ""
echo "Neste steg (kjøres av deg):"
echo "  cd $REPO && flutter analyze --no-pub 2>&1 | grep -E \"error|issues found\""
echo "  Lag siden med adressen bonusvarsel.no/betalo (se skript 66), ellers peker AI-en til en side som ikke finnes."
