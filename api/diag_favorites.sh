#!/bin/bash
set -e
TARGET="server.js"
cp "$TARGET" "$TARGET.bak_diag_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
with open("server.js","r",encoding="utf-8") as f:
    src = f.read()

# Punkt 1: etter fetchAllCampaigns
p1_old = """    const campaigns = await fetchAllCampaigns('elite');
    if (!campaigns.length) return;"""
p1_new = """    const campaigns = await fetchAllCampaigns('elite');
    console.log('[DIAG] campaigns hentet:', campaigns.length);
    if (!campaigns.length) { console.log('[DIAG] AVBRYTER: ingen kampanjer'); return; }
    console.log('[DIAG] antall enheter:', Object.keys(deviceFavorites).length);"""

# Punkt 2: inni device-loopen etter favs-sjekk
p2_old = """      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      if (!allFavSlugs.length) continue;"""
p2_new = """      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      console.log('[DIAG] enhet', deviceId, 'favs:', JSON.stringify(allFavSlugs), 'email:', favs.email || 'INGEN');
      if (!allFavSlugs.length) continue;"""

# Punkt 3: før newCampaigns-sjekk
p3_old = """      if (!newCampaigns.length) continue;"""
p3_new = """      console.log('[DIAG] enhet', deviceId, 'matchede kampanjer:', newCampaigns.length, newCampaigns.map(c=>c.slug).join(','));
      if (!newCampaigns.length) { console.log('[DIAG] enhet', deviceId, 'INGEN match – hopper over'); continue; }"""

for old,new,name in [(p1_old,p1_new,"P1"),(p2_old,p2_new,"P2"),(p3_old,p3_new,"P3")]:
    n = src.count(old)
    if n == 1:
        src = src.replace(old,new); print(f"✅ {name} lagt inn")
    elif n == 0:
        print(f"⚠️  {name} mønster ikke funnet – hopper over")
    else:
        print(f"⚠️  {name} funnet {n} ganger – hopper over (for usikkert)")

with open("server.js","w",encoding="utf-8") as f:
    f.write(src)
PYTHON

node --check "$TARGET" && echo "✅ node --check OK" || { echo "❌ Syntaksfeil – gjenoppretter"; cp "$TARGET".bak_diag_* "$TARGET"; exit 1; }
