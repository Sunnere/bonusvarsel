#!/bin/bash
set -e
TARGET="server.js"
cp "$TARGET" "$TARGET.bak_favsrc_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
with open("server.js","r",encoding="utf-8") as f:
    src = f.read()

# Finn linjen i checkFavoritesAndNotify som henter SAS-only, bytt til kombinert
# Den ligger rett før "if (!campaigns.length) return;" (linje ~1171)
old = """    const campaigns = await fetchCampaigns();
    if (!campaigns.length) return;"""

new = """    const campaigns = await fetchAllCampaigns('elite');
    if (!campaigns.length) return;"""

count = src.count(old)
if count == 0:
    print("❌ Fant ikke mønsteret – sjekk manuelt rundt linje 1171")
    raise SystemExit(1)
elif count > 1:
    print(f"⚠️  Fant {count} treff – for usikkert, stopper")
    raise SystemExit(1)

src = src.replace(old, new)
print("✅ checkFavoritesAndNotify bruker nå fetchAllCampaigns (SAS+Trumf)")

with open("server.js","w",encoding="utf-8") as f:
    f.write(src)
PYTHON

node --check "$TARGET" && echo "✅ node --check OK" || { echo "❌ Syntaksfeil – gjenoppretter"; cp "$TARGET".bak_favsrc_* "$TARGET"; exit 1; }
