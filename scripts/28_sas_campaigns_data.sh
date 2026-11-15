#!/usr/bin/env bash
# 28_sas_campaigns_data.sh
# Lager data/sas_campaigns.json fra SAS Online Shopping sine kampanjer (kopiert fra nettsiden).
# Oppdater manuelt når kampanjene endrer seg. Kilde: https://onlineshopping.flysas.com/nb-NO
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
OUT_DIR="$ROOT/data"
OUT="$OUT_DIR/sas_campaigns.json"
mkdir -p "$OUT_DIR"

python3 - "$OUT" <<'PY'
import sys, json
out = sys.argv[1]
CHECKED = "2026-10-19"

raw = [
    ("Outnorth", "doble", 50, "per100kr", "aktuell"),
    ("Lensway", "ekstra", 75, "per100kr", "aktuell"),
    ("dekkonline.com", "doble", 20, "per100kr", "aktuell"),
    ("CS Megastore", "doble", 20, "per100kr", "aktuell"),
    ("Ideal of Sweden", "ekstra", 100, "per100kr", "aktuell"),
    ("Strim", "ekstra", 2000, "fast", "aktuell"),
    ("Albert", "doble", 1000, "fast", "aktuell"),
    ("ICE", "ekstra", 2500, "fast", "aktuell"),
    ("Nextory", "doble", 500, "fast", "aktuell"),
    ("Kajakk og Fritid", "doble", 50, "per100kr", "aktuell"),
    ("KICKS", "doble", 50, "per100kr", "aktuell"),
    ("partyking", "doble", 50, "per100kr", "aktuell"),
    ("Autodude", "ekstra", 50, "per100kr", "aktuell"),
    ("Fortum Strøm", "ekstra", 4000, "fast", "aktuell"),
    ("Aarke", "doble", 50, "per100kr", "aktuell"),
    ("Selected", "doble", 50, "per100kr", "aktuell"),
    ("Authentic Europe", "doble", 50, "per100kr", "aktuell"),
    ("iRobot", "ukjent", 25, "per100kr", "ny"),
    ("Selected", "doble", 50, "per100kr", "ny"),
    ("Steamery", "doble", 25, "per100kr", "ny"),
    ("Aarke", "doble", 50, "per100kr", "ny"),
    ("Pergolux", "ukjent", 25, "per100kr", "ny"),
    ("Pace", "ukjent", 50, "per100kr", "ny"),
    ("Løpeshop", "ukjent", 25, "per100kr", "ny"),
    ("Stille", "ukjent", 50, "per100kr", "ny"),
    ("Trivelia", "ukjent", 1500, "fast", "ny"),
    ("NiteCaps", "ukjent", 1500, "fast", "ny"),
    ("Floyd", "ukjent", 25, "per100kr", "ny"),
    ("Calstop", "ukjent", 1000, "fast", "ny"),
    ("Onyx Cookware", "ukjent", 25, "per100kr", "ny"),
    ("Xlash", "ukjent", 25, "per100kr", "ny"),
    ("Mulberry", "ukjent", 25, "per100kr", "ny"),
    ("Trøndermobil", "ukjent", 2000, "fast", "ny"),
    ("Babybanden", "ukjent", 25, "per100kr", "ny"),
    ("Bokia", "ukjent", 50, "per100kr", "ny"),
    ("Camilla Phil", "ukjent", 50, "per100kr", "ny"),
]

seen = set()
entries = []
for name, typ, value, unit, section in raw:
    key = (name.lower(), section)
    if key in seen:
        continue
    seen.add(key)
    entries.append({
        "name": name,
        "section": section,
        "bonus_type": typ,
        "points": value,
        "unit": unit,
        "nivaapoeng_pct": 20,
        "checked_at": CHECKED,
    })

doc = {
    "source": "SAS Online Shopping (nb-NO), kopiert manuelt",
    "source_url": "https://onlineshopping.flysas.com/nb-NO",
    "checked_at": CHECKED,
    "note": "Oppdateres manuelt.",
    "entries": entries,
}
json.dump(doc, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print(f"Skrev {len(entries)} kampanjer til {out}")
PY

python3 -c "import json; d=json.load(open('$OUT')); assert d['entries'], 'tom liste'; print('OK: gyldig JSON,', len(d['entries']), 'oppføringer')"
