#!/bin/bash
set -e
TARGET="functions/index.js"
cp "$TARGET" "$TARGET.bak_safelink_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
with open("functions/index.js","r",encoding="utf-8") as f:
    src = f.read()
old = "function bvOfferLink(c){ return c.url || c.link || (bvIsTrumf(c)?BV_TRUMF_HOME:(c.slug?BV_SAS_BASE+c.slug:BV_SAS_HOME)); }"
new = "function bvOfferLink(c){ return bvIsTrumf(c) ? BV_TRUMF_HOME : BV_SAS_HOME; }"
if old in src:
    src = src.replace(old, new); print("✅ bvOfferLink byttet til trygg portal-hjem")
elif new in src:
    print("ℹ️  Allerede trygg portal-hjem")
else:
    print("❌ Fant ikke bvOfferLink"); raise SystemExit(1)
with open("functions/index.js","w",encoding="utf-8") as f:
    f.write(src)
PYTHON

node --check "$TARGET" && echo "✅ node --check OK" || { echo "❌ Syntaksfeil – gjenoppretter"; cp "$TARGET".bak_safelink_* "$TARGET"; exit 1; }
