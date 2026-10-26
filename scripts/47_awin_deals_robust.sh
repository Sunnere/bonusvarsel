#!/bin/bash
# 47_awin_deals_robust.sh – gjør awin_deals.py tålig for feil (nøkkel med /, døde bildelenker)
# Kjør fra repo-roten:  bash scripts/47_awin_deals_robust.sh
set -e
cd "$(git rev-parse --show-toplevel)"
cat > scripts/awin_deals.py <<'PYEOF'
#!/usr/bin/env python3
"""Ukens deal: henter Awin-produktfeeder, finner største prisfall, lager
ferdige Cloudinary-bilder og skriver data/awin-deals.json for Make.
Krever env AWIN_FEED_KEY. Kun Python stdlib."""
import csv, gzip, io, json, os, sys, urllib.error, urllib.parse, urllib.request, datetime

PUBLISHER = "3126086"
KEY = os.environ.get("AWIN_FEED_KEY", "").strip().strip("/")
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
    try:
        rows = list(csv.DictReader(io.StringIO(get(base + "/feedList").decode("utf-8", "ignore"))))
    except urllib.error.HTTPError as e:
        sys.exit(f"Awin feedList svarte {e.code} – sjekk AWIN_FEED_KEY (lengde {len(KEY)}, skal være 32 tegn)")
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
        try:
            raw = get(url)
        except Exception as e:
            print(f"Hopper over feed {ADVERTISERS[adv]}: {e}")
            continue
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
            imgs = [u for u in (p.get("merchant_image_url"), p.get("aw_image_url")) if u]
            img = imgs[0] if imgs else ""
            if pct < MIN_PCT or not img or not p.get("aw_deep_link"):
                continue
            cands.append({"advertiser_id": adv, "brand": ADVERTISERS[adv], "product_id": p["aw_product_id"],
                          "name": p["product_name"], "price": new, "old_price": old, "pct": pct,
                          "image": img, "images": imgs, "link": p["aw_deep_link"]})
    cands = [d for d in cands if d["product_id"] not in prev]  # aldri samme produkt to uker på rad
    cands.sort(key=lambda d: -d["pct"])
    deals, per = [], {}
    for d in cands:
        if per.get(d["brand"], 0) >= MAX_PER_BRAND:
            continue
        pid = None
        for u in d.pop("images"):
            try:
                pid = upload(u)
                break
            except Exception as e:
                print(f"Bilde feilet for {d['name']}: {e}")
        if not pid:
            continue
        per[d["brand"]] = per.get(d["brand"], 0) + 1
        d["short_name"] = short_name(d["name"], d["brand"])
        d["headline"] = f"-{d['pct']} % på {d['short_name']}"
        d["price_text"] = f"Nå {nok(d['price'])} · før {nok(d['old_price'])}"
        d["media_url"] = ad_url(pid, d["brand"], d["headline"], d["price_text"])
        deals.append(d)
        if len(deals) >= MAX_DEALS:
            break
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
python3 -m py_compile scripts/awin_deals.py && echo "✅ scripts/awin_deals.py oppdatert og kompilerer"
