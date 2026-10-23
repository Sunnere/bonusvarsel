#!/bin/bash
# 46_awin_ukens_deal.sh – legger inn Awin «Ukens deal» (script + GitHub Action)
# Kjør fra repo-roten:  bash scripts/46_awin_ukens_deal.sh
set -e
cd "$(git rev-parse --show-toplevel)"
mkdir -p scripts data .github/workflows

cat > scripts/awin_deals.py <<'PYEOF'
#!/usr/bin/env python3
"""Ukens deal: henter Awin-produktfeeder, finner største prisfall, lager
ferdige Cloudinary-bilder og skriver data/awin-deals.json for Make.
Krever env AWIN_FEED_KEY. Kun Python stdlib."""
import csv, gzip, io, json, os, sys, urllib.parse, urllib.request, datetime

PUBLISHER = "3126086"
KEY = os.environ.get("AWIN_FEED_KEY", "").strip()
# Annonsører som står på bonusshop.no (advertiserId -> visningsnavn)
ADVERTISERS = {
    "25181": "Dyson",
    "81671": "SharkNinja",
    "62437": "Pergolux",
    "109844": "DB Journey",
}
MAX_DEALS, MAX_PER_BRAND, MIN_PCT, MIN_PRICE = 3, 2, 15, 200
CLOUD, PRESET = "ds3xrvivm", "bonusshop_ads"
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "awin-deals.json")

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "bonusshop-deals/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()

def nok(v):
    return f"{int(round(v)):,}".replace(",", " ") + " kr"

def short_name(name, brand):
    n = name.replace("™", "").replace("®", "")
    if n.lower().startswith(brand.lower()):
        n = n[len(brand):].strip(" -–")
    out = ""
    for w in n.split():
        if len(out) + len(w) + 1 > 24:
            break
        out = (out + " " + w).strip()
    return out or n[:24]

def t(s):  # Cloudinary tekst-lag: dobbel-escape , / %
    return urllib.parse.quote(s, safe="").replace("%25", "%2525").replace("%2C", "%252C").replace("%2F", "%252F")

def upload(image_url):
    data = urllib.parse.urlencode({"upload_preset": PRESET, "file": image_url, "tags": "awin_deal"}).encode()
    req = urllib.request.Request(f"https://api.cloudinary.com/v1_1/{CLOUD}/image/upload", data=data)
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)["public_id"]

def ad_url(pid, brand, headline, priceline):
    return ("https://res.cloudinary.com/%s/image/upload/"
            "c_pad,w_760,h_600,b_white/r_32/"
            "c_lpad,w_1080,h_900,g_south,b_rgb:0B1A30/c_lpad,w_1080,h_1080,g_north,b_rgb:0B1A30/"
            "co_rgb:D4AF37,l_text:Montserrat_40_bold_letter_spacing_8:%s/fl_layer_apply,g_north_west,x_64,y_56/"
            "co_white,c_fit,w_950,l_text:Montserrat_72_bold_line_spacing_-12:%s/fl_layer_apply,g_north_west,x_60,y_112/"
            "co_rgb:0B1A30,b_rgb:D4AF37,l_text:Montserrat_40_bold:%s/fl_layer_apply,g_south,y_70/"
            "f_jpg/q_auto/%s.jpg") % (CLOUD, t(brand.upper()), t(headline), t("    " + priceline + "    "), pid)

def main():
    if not KEY:
        sys.exit("AWIN_FEED_KEY mangler")
    base = f"https://ui.awin.com/productdata-darwin-download/publisher/{PUBLISHER}/{KEY}/1"
    rows = list(csv.DictReader(io.StringIO(get(base + "/feedList").decode("utf-8", "ignore"))))
    feeds = {}
    for r in rows:
        if r["Advertiser ID"] in ADVERTISERS and r["Membership Status"] == "active" and r["Primary Region"] == "NO":
            feeds.setdefault(r["Advertiser ID"], r["URL"])
    prev = set()
    if os.path.exists(OUT):
        try:
            prev = {d["product_id"] for d in json.load(open(OUT)).get("deals", [])}
        except Exception:
            pass
    cands = []
    for adv, url in feeds.items():
        raw = get(url)
        try:
            raw = gzip.decompress(raw)
        except OSError:
            pass
        for p in csv.DictReader(io.StringIO(raw.decode("utf-8", "ignore"))):
            try:
                new, old = float(p.get("search_price") or 0), float(p.get("product_price_old") or 0)
            except ValueError:
                continue
            if p.get("in_stock") not in ("1", "yes", "true") or new < MIN_PRICE or old <= new:
                continue
            pct = round((1 - new / old) * 100)
            img = p.get("merchant_image_url") or p.get("aw_image_url")
            if pct < MIN_PCT or not img or not p.get("aw_deep_link"):
                continue
            cands.append({"advertiser_id": adv, "brand": ADVERTISERS[adv], "product_id": p["aw_product_id"],
                          "name": p["product_name"], "price": new, "old_price": old, "pct": pct,
                          "image": img, "link": p["aw_deep_link"]})
    cands = [d for d in cands if d["product_id"] not in prev]  # aldri samme produkt to uker på rad
    cands.sort(key=lambda d: -d["pct"])
    deals, per = [], {}
    for d in cands:
        if per.get(d["brand"], 0) >= MAX_PER_BRAND:
            continue
        per[d["brand"]] = per.get(d["brand"], 0) + 1
        deals.append(d)
        if len(deals) >= MAX_DEALS:
            break
    for d in deals:
        d["short_name"] = short_name(d["name"], d["brand"])
        d["headline"] = f"-{d['pct']} % på {d['short_name']}"
        d["price_text"] = f"Nå {nok(d['price'])} · før {nok(d['old_price'])}"
        d["media_url"] = ad_url(upload(d["image"]), d["brand"], d["headline"], d["price_text"])
    out = {"generated": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
           "count": len(deals), "deals": deals,
           "media_items": ",".join(json.dumps({"type": "image", "url": d["media_url"]}) for d in deals),
           "summary": " | ".join(f"{d['brand']}: {d['name']} {nok(d['price'])} (før {nok(d['old_price'])}, -{d['pct']} %)" for d in deals)}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w"), ensure_ascii=False, indent=1)
    print(f"{len(deals)} deals av {len(cands)} kandidater skrevet til {OUT}")

if __name__ == "__main__":
    main()
PYEOF

cat > .github/workflows/awin-deals.yml <<'YMLEOF'
name: Awin ukens deal
on:
  schedule:
    - cron: "0 6 * * 6"   # lørdag 06:00 UTC
  workflow_dispatch: {}
permissions:
  contents: write
jobs:
  deals:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Finn ukens deals
        env:
          AWIN_FEED_KEY: ${{ secrets.AWIN_FEED_KEY }}
        run: python3 scripts/awin_deals.py
      - name: Commit data/awin-deals.json
        run: |
          git config user.name "awin-deals-bot"
          git config user.email "actions@users.noreply.github.com"
          git add data/awin-deals.json
          git diff --cached --quiet || git commit -m "Awin ukens deal $(date -u +%F)"
          git push
YMLEOF

# Dagens deals (allerede postet 23.10) – så de ikke postes igjen i morgen
[ -f data/awin-deals.json ] || cat > data/awin-deals.json <<'JSONEOF'
{
 "generated": "2026-10-23T11:17:04Z",
 "count": 2,
 "deals": [
  {
   "advertiser_id": "25181",
   "brand": "Dyson",
   "product_id": "43434881899",
   "name": "Dyson PencilVac™ Fluffycones",
   "price": 4419.0,
   "old_price": 5599.0,
   "pct": 21,
   "image": "https://d3d71ba2asa5oz.cloudfront.net/12009508/images/492689-01_pencilvac-fluffycones.jpg",
   "link": "https://www.awin1.com/pclick.php?p=43434881899&a=3126086&m=25181",
   "short_name": "PencilVac Fluffycones",
   "headline": "-21 % på PencilVac Fluffycones",
   "price_text": "Nå 4 419 kr · før 5 599 kr",
   "media_url": "https://res.cloudinary.com/ds3xrvivm/image/upload/c_pad,w_760,h_600,b_white/r_32/c_lpad,w_1080,h_900,g_south,b_rgb:0B1A30/c_lpad,w_1080,h_1080,g_north,b_rgb:0B1A30/co_rgb:D4AF37,l_text:Montserrat_40_bold_letter_spacing_8:DYSON/fl_layer_apply,g_north_west,x_64,y_56/co_white,c_fit,w_950,l_text:Montserrat_72_bold_line_spacing_-12:-21%20%2525%20p%C3%A5%20PencilVac%20Fluffycones/fl_layer_apply,g_north_west,x_60,y_112/co_rgb:0B1A30,b_rgb:D4AF37,l_text:Montserrat_40_bold:%20%20%20%20N%C3%A5%204%20419%20kr%20%C2%B7%20f%C3%B8r%205%20599%20kr%20%20%20%20/fl_layer_apply,g_south,y_70/f_jpg/q_auto/bxhv1mtk1rwonjy9lnip.jpg"
  },
  {
   "advertiser_id": "25181",
   "brand": "Dyson",
   "product_id": "44919419792",
   "name": "Dyson Find+Follow™ Purifier Cool PC3",
   "price": 6529.0,
   "old_price": 8299.0,
   "pct": 21,
   "image": "https://d3d71ba2asa5oz.cloudfront.net/12009508/images/491395-01_find%2bfollow-purifier-cool_pc3.jpeg",
   "link": "https://www.awin1.com/pclick.php?p=44919419792&a=3126086&m=25181",
   "short_name": "Find+Follow Purifier",
   "headline": "-21 % på Find+Follow Purifier",
   "price_text": "Nå 6 529 kr · før 8 299 kr",
   "media_url": "https://res.cloudinary.com/ds3xrvivm/image/upload/c_pad,w_760,h_600,b_white/r_32/c_lpad,w_1080,h_900,g_south,b_rgb:0B1A30/c_lpad,w_1080,h_1080,g_north,b_rgb:0B1A30/co_rgb:D4AF37,l_text:Montserrat_40_bold_letter_spacing_8:DYSON/fl_layer_apply,g_north_west,x_64,y_56/co_white,c_fit,w_950,l_text:Montserrat_72_bold_line_spacing_-12:-21%20%2525%20p%C3%A5%20Find%2BFollow%20Purifier/fl_layer_apply,g_north_west,x_60,y_112/co_rgb:0B1A30,b_rgb:D4AF37,l_text:Montserrat_40_bold:%20%20%20%20N%C3%A5%206%20529%20kr%20%C2%B7%20f%C3%B8r%208%20299%20kr%20%20%20%20/fl_layer_apply,g_south,y_70/f_jpg/q_auto/kjivwxdfqh01lxmw1h9c.jpg"
  }
 ],
 "summary": "Dyson: Dyson PencilVac™ Fluffycones 4 419 kr (før 5 599 kr, -21 %) | Dyson: Dyson Find+Follow™ Purifier Cool PC3 6 529 kr (før 8 299 kr, -21 %)",
 "media_items": "{\"type\": \"image\", \"url\": \"https://res.cloudinary.com/ds3xrvivm/image/upload/c_pad,w_760,h_600,b_white/r_32/c_lpad,w_1080,h_900,g_south,b_rgb:0B1A30/c_lpad,w_1080,h_1080,g_north,b_rgb:0B1A30/co_rgb:D4AF37,l_text:Montserrat_40_bold_letter_spacing_8:DYSON/fl_layer_apply,g_north_west,x_64,y_56/co_white,c_fit,w_950,l_text:Montserrat_72_bold_line_spacing_-12:-21%20%2525%20p%C3%A5%20PencilVac%20Fluffycones/fl_layer_apply,g_north_west,x_60,y_112/co_rgb:0B1A30,b_rgb:D4AF37,l_text:Montserrat_40_bold:%20%20%20%20N%C3%A5%204%20419%20kr%20%C2%B7%20f%C3%B8r%205%20599%20kr%20%20%20%20/fl_layer_apply,g_south,y_70/f_jpg/q_auto/bxhv1mtk1rwonjy9lnip.jpg\"},{\"type\": \"image\", \"url\": \"https://res.cloudinary.com/ds3xrvivm/image/upload/c_pad,w_760,h_600,b_white/r_32/c_lpad,w_1080,h_900,g_south,b_rgb:0B1A30/c_lpad,w_1080,h_1080,g_north,b_rgb:0B1A30/co_rgb:D4AF37,l_text:Montserrat_40_bold_letter_spacing_8:DYSON/fl_layer_apply,g_north_west,x_64,y_56/co_white,c_fit,w_950,l_text:Montserrat_72_bold_line_spacing_-12:-21%20%2525%20p%C3%A5%20Find%2BFollow%20Purifier/fl_layer_apply,g_north_west,x_60,y_112/co_rgb:0B1A30,b_rgb:D4AF37,l_text:Montserrat_40_bold:%20%20%20%20N%C3%A5%206%20529%20kr%20%C2%B7%20f%C3%B8r%208%20299%20kr%20%20%20%20/fl_layer_apply,g_south,y_70/f_jpg/q_auto/kjivwxdfqh01lxmw1h9c.jpg\"}"
}
JSONEOF

echo "✅ Filer laget:"
ls -la scripts/awin_deals.py .github/workflows/awin-deals.yml data/awin-deals.json
echo
echo "Branch du står på : $(git branch --show-current)"
echo "Standard-branch   : $(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')"
echo
echo "Neste steg:"
echo "  git add scripts/awin_deals.py .github/workflows/awin-deals.yml data/awin-deals.json"
echo "  git commit -m 'Awin ukens deal'"
echo "  git push"
