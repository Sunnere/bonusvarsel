#!/bin/bash
# 48: Ukens deal – legg til Acer, Sofas and More, Dr. Stine + bruk rrp_price som førpris (Acer)
set -e
cd "$(git rev-parse --show-toplevel)"
F=scripts/awin_deals.py
[ -f "$F" ] || { echo "Finner ikke $F"; exit 1; }
cp "$F" "$F.bak48"
python3 - "$F" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
if '"24784": "Acer"' not in s:
    old='    "109844": "DB Journey",\n}'
    assert old in s, "fant ikke ADVERTISERS-slutten"
    s=s.replace(old,'    "109844": "DB Journey",\n    "24784": "Acer",\n    "116085": "Sofas and More",\n    "125850": "Dr. Stine",\n}')
old='float(p.get("product_price_old") or 0)'
if old in s:
    s=s.replace(old,'float(p.get("product_price_old") or p.get("rrp_price") or 0)')
open(p,"w").write(s)
print("OK: butikker og rrp_price lagt inn")
PY
python3 -m py_compile "$F" && echo "Syntaks OK"
git add "$F"
git commit -m "Ukens deal: Acer, Sofas and More, Dr. Stine + rrp_price som førpris" || true
git push
echo "Ferdig. Kjør gjerne: gh workflow run awin-deals.yml"
