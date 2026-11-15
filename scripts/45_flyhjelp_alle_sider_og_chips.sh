#!/bin/bash
# 45_flyhjelp_alle_sider_og_chips.sh
#  1) Flyhjelp vises på alle sider igjen (annonser vi tjener på får stå)
#  2) Bobler (chips) i «Bonusvarsler»-kortet får luft mellom radene
# Kjør:  bash scripts/45_flyhjelp_alle_sider_og_chips.sh
set -e
REPO="${REPO:-$HOME/bonusvarsel}"
AD="$REPO/lib/services/ad_service.dart"
AL="$REPO/lib/pages/bonusvarsel_alerts_page.dart"
for f in "$AD" "$AL"; do [ -f "$f" ] || { echo "FEIL: fant ikke $f"; exit 1; }; done
for f in "$AD" "$AL"; do cp -n "$f" "$f.bak_45" || true; done

python3 - "$AD" "$AL" <<'PY'
import re, sys
ad_path, al_path = sys.argv[1], sys.argv[2]

ad = open(ad_path, encoding="utf-8").read()
ad, n = re.subn(r"tags: \['reis', 'flyhjelp'[^\]]*\],", "tags: ['reis', 'flyhjelp'],", ad)
if n != 1:
    sys.exit("FEIL: fant ikke flyhjelp_1-tagger")
open(ad_path, "w", encoding="utf-8").write(ad)
print("ad_service.dart: Flyhjelp vises på alle sider")

al = open(al_path, encoding="utf-8").read()
old = "Wrap(spacing: 8, children: [\n        _hchip(\"Aktive\""
new = "Wrap(spacing: 8, runSpacing: 8, children: [\n        _hchip(\"Aktive\""
if "runSpacing: 8, children: [\n        _hchip(\"Aktive\"" in al:
    print("bonusvarsel_alerts_page.dart: radavstand finnes fra før - hopper over")
elif al.count(old) != 1:
    sys.exit("FEIL: fant ikke chip-raden")
else:
    open(al_path, "w", encoding="utf-8").write(al.replace(old, new))
    print("bonusvarsel_alerts_page.dart: la inn radavstand mellom boblene")
PY

echo
echo "== Kontroll"
grep -n "tags: \['reis', 'flyhjelp'" "$AD"
grep -n "runSpacing: 8, children: \[" "$AL" | head -2
if command -v flutter >/dev/null 2>&1; then
  echo
  echo "== flutter analyze (kun feil)"
  (cd "$REPO" && flutter analyze --no-pub lib/services/ad_service.dart lib/pages/bonusvarsel_alerts_page.dart 2>&1 | grep -E " error •" || echo "Ingen feil")
fi
echo
echo "Ferdig. Backup: *.bak_45. Start appen på nytt."
