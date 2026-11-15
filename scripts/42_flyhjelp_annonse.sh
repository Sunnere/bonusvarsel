#!/bin/bash
# 42_flyhjelp_annonse.sh – legger Flyhjelp-annonse i Reise-fanen og lar Reise-fanen bare vise reis-annonser
# Kjør:  bash scripts/42_flyhjelp_annonse.sh      (test på kopi:  REPO=/tmp/bv_test bash scripts/42_flyhjelp_annonse.sh)
set -e
REPO="${REPO:-$HOME/bonusvarsel}"
AD="$REPO/lib/services/ad_service.dart"
TR="$REPO/lib/pages/travel_page.dart"
[ -f "$AD" ] && [ -f "$TR" ] || { echo "FEIL: fant ikke ad_service.dart / travel_page.dart i $REPO"; exit 1; }
cp -n "$AD" "$AD.bak_42" || true
cp -n "$TR" "$TR.bak_42" || true

python3 - "$AD" "$TR" <<'PY'
import sys
ad_path, tr_path = sys.argv[1], sys.argv[2]

# 1) Flyhjelp-annonsen i inventaret
ad = open(ad_path, encoding="utf-8").read()
if "id: 'flyhjelp_1'" in ad:
    print("ad_service.dart: flyhjelp_1 finnes fra før - hopper over")
else:
    marker = "AdSlot(\n          id: 'betalo_reise',"
    if ad.count(marker) != 1:
        sys.exit("FEIL: fant ikke betalo_reise-blokken akkurat én gang i ad_service.dart")
    snippet = (
        "AdSlot(\n"
        "          id: 'flyhjelp_1',\n"
        "          isSponsored: true,\n"
        "          guaranteePerDay: 3,\n"
        "          title: 'Forsinket fly? Få kompensasjon',\n"
        "          body: 'Du kan ha krav på opptil 600 €. Sjekk kravet gratis hos Flyhjelp.',\n"
        "          cta: 'Sjekk kravet ditt',\n"
        "          link: 'https://dot.flyhjelp.no/t/t?a=1870470470&as=2074526845&t=2&tk=1',\n"
        "          tags: ['reis', 'flyhjelp'],\n"
        "        ),\n"
        "        "
    )
    ad = ad.replace(marker, snippet + marker)
    open(ad_path, "w", encoding="utf-8").write(ad)
    print("ad_service.dart: la inn flyhjelp_1")

# 2) Reise-fanen viser bare annonser merket 'reis'
tr = open(tr_path, encoding="utf-8").read()
old = "AdService.instance.pickAds(placement: placement, count: 1),"
new = "AdService.instance.pickAds(placement: placement, count: 1, requireAnyTags: [placement]),"
if "requireAnyTags: [placement]" in tr:
    print("travel_page.dart: allerede filtrert - hopper over")
elif tr.count(old) != 1:
    sys.exit("FEIL: fant ikke pickAds-kallet akkurat én gang i travel_page.dart")
else:
    open(tr_path, "w", encoding="utf-8").write(tr.replace(old, new))
    print("travel_page.dart: Reise viser nå bare reis-annonser")
PY

echo
echo "== Kontroll"
grep -n "flyhjelp_1" "$AD"
grep -n "requireAnyTags: \[placement\]" "$TR"
if command -v flutter >/dev/null 2>&1; then
  echo
  echo "== flutter analyze (kun feil)"
  (cd "$REPO" && flutter analyze --no-pub lib/services/ad_service.dart lib/pages/travel_page.dart 2>&1 | grep -E " error •|No issues found" || echo "Ingen feil")
fi
echo
echo "Ferdig. Backup: *.bak_42. Test i appen: Reise-fanen skal vise Flyhjelp med «Annonse»-merke."
