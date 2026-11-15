#!/bin/bash
# 44_flyhjelp_mindre_og_kun_reise.sh
#  1) Bildekortet blir lavere (bildet beskjæres nedenfra, toppen med logo og «Krev kompensasjon» beholdes)
#  2) Flyhjelp vises bare der den er satt til (standard: Reise-fanen) - ikke Poeng, Spar osv.
#  3) Chat-knappen (flytende boble) blir mindre og litt gjennomsiktig så den dekker mindre
# Kjør:  bash scripts/44_flyhjelp_mindre_og_kun_reise.sh
# Valg:  ASPECT=1.5 (høyere tall = lavere kort, f.eks. 1.7)   PLACES="reis" (flere: PLACES="reis,poeng")
set -e
REPO="${REPO:-$HOME/bonusvarsel}"
ASPECT="${ASPECT:-1.5}"
PLACES="${PLACES:-reis}"
AD="$REPO/lib/services/ad_service.dart"
CARD="$REPO/lib/widgets/ad_slot.dart"
HOME_P="$REPO/lib/pages/home_page.dart"
for f in "$AD" "$CARD" "$HOME_P"; do [ -f "$f" ] || { echo "FEIL: fant ikke $f"; exit 1; }; done
grep -q "_imageCard(" "$CARD" || { echo "FEIL: kjør scripts/43_flyhjelp_bilde.sh først"; exit 1; }
for f in "$AD" "$CARD" "$HOME_P"; do cp -n "$f" "$f.bak_44" || true; done

python3 - "$AD" "$CARD" "$HOME_P" "$ASPECT" "$PLACES" <<'PY'
import re, sys
ad_path, card_path, home_path, aspect, places = sys.argv[1:6]

# 1) Lavere bildekort
card = open(card_path, encoding="utf-8").read()
card, n = re.subn(r"AspectRatio\(aspectRatio: [0-9.]+, child: image\)",
                  "AspectRatio(aspectRatio: %s, child: image)" % aspect, card)
if n != 1:
    sys.exit("FEIL: fant ikke AspectRatio i bildekortet")
if "Alignment.topCenter" not in card:
    a = "img,\n            fit: BoxFit.cover,\n"
    b = "Image.asset(img, fit: BoxFit.cover)"
    if card.count(a) != 1 or card.count(b) != 1:
        sys.exit("FEIL: fant ikke Image.network/Image.asset i bildekortet")
    card = card.replace(a, a + "            alignment: Alignment.topCenter,\n")
    card = card.replace(b, "Image.asset(img, fit: BoxFit.cover, alignment: Alignment.topCenter)")
open(card_path, "w", encoding="utf-8").write(card)
print("ad_slot.dart: bildekort satt til sideforhold %s (beskjært fra toppen)" % aspect)

# 2) Flyhjelp bare på valgte plasseringer
ad = open(ad_path, encoding="utf-8").read()
place_tags = ", ".join("'place:%s'" % p.strip().lower() for p in places.split(",") if p.strip())
ad, n = re.subn(r"tags: \['reis', 'flyhjelp'[^\]]*\],",
                "tags: ['reis', 'flyhjelp', %s]," % place_tags, ad)
if n != 1:
    sys.exit("FEIL: fant ikke flyhjelp_1-tagger")
if "startsWith('place:')" not in ad:
    anchor = "    if (enforceSessionCap) {\n"
    if ad.count(anchor) != 1:
        sys.exit("FEIL: fant ikke enforceSessionCap-blokken akkurat én gang")
    flt = (
        "    // Annonser med 'place:<navn>'-tagg vises bare på de plasseringene.\n"
        "    pool = pool.where((a) {\n"
        "      final places = a.tags\n"
        "          .where((t) => t.startsWith('place:'))\n"
        "          .map((t) => t.substring(6).toLowerCase());\n"
        "      return places.isEmpty || places.contains(placement.toLowerCase());\n"
        "    }).toList();\n\n"
    )
    ad = ad.replace(anchor, flt + anchor)
open(ad_path, "w", encoding="utf-8").write(ad)
print("ad_service.dart: Flyhjelp vises bare på: %s" % places)

# 3) Mindre chat-knapp
home = open(home_path, encoding="utf-8").read()
if "FloatingActionButton.small(" in home:
    print("home_page.dart: chat-knappen er allerede liten - hopper over")
else:
    old = "floatingActionButton: FloatingActionButton(\n        backgroundColor: Theme.of(context).scaffoldBackgroundColor,"
    new = ("floatingActionButton: FloatingActionButton.small(\n"
           "        elevation: 2,\n"
           "        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.88),")
    if home.count(old) != 1:
        sys.exit("FEIL: fant ikke chat-knappen i home_page.dart")
    open(home_path, "w", encoding="utf-8").write(home.replace(old, new))
    print("home_page.dart: chat-knappen gjort mindre")
PY

echo
echo "== Kontroll"
grep -n "aspectRatio:" "$CARD" | head -3
grep -n "place:" "$AD" | head -4
grep -n "FloatingActionButton.small" "$HOME_P"
if command -v flutter >/dev/null 2>&1; then
  echo
  echo "== flutter analyze (kun feil)"
  (cd "$REPO" && flutter analyze --no-pub lib/services/ad_service.dart lib/widgets/ad_slot.dart lib/pages/home_page.dart 2>&1 | grep -E " error •" || echo "Ingen feil")
fi
echo
echo "Ferdig. Backup: *.bak_44. Start appen på nytt: Flyhjelp bare i Reise, lavere kort, mindre chat-knapp."
