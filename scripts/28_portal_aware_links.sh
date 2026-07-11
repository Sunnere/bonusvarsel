#!/bin/bash
set -e
TARGET="functions/index.js"

if [ ! -f "$TARGET" ]; then
  echo "❌ Finner ikke $TARGET – er du i bonusvarsel-mappen?"
  exit 1
fi

# Backup
cp "$TARGET" "$TARGET.bak_portal_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
import re, io

with open("functions/index.js", "r", encoding="utf-8") as f:
    src = f.read()

# ── 1) Legg til portal-konstanter etter BV_SAS_BASE (om ikke finnes) ──
if "BV_TRUMF_HOME" not in src:
    src = src.replace(
        "const BV_SAS_BASE = 'https://onlineshopping.flysas.com/nb-NO/butikk/';",
        "const BV_SAS_BASE = 'https://onlineshopping.flysas.com/nb-NO/butikk/';\n"
        "const BV_SAS_HOME  = 'https://onlineshopping.flysas.com/nb-NO';\n"
        "const BV_TRUMF_HOME = 'https://trumfnetthandel.no';"
    )

# ── 2) Bytt endepunkt /api/offers → /api/campaigns + parsing ──
src = src.replace(
    "const res = await axios.get(`${RAILWAY_URL}/api/offers`, {\n      params: { program, limit: 5 }, timeout: 8000,\n    });\n    return res.data?.items || res.data?.offers || [];",
    "const res = await axios.get(`${RAILWAY_URL}/api/campaigns`, { timeout: 8000 });\n"
    "    const all = res.data?.campaigns || [];\n"
    "    if (program === 'trumf_netthandel') return all.filter(c => String(c.source||'').toLowerCase() === 'trumf');\n"
    "    if (program === 'sas_online')      return all.filter(c => String(c.source||'').toLowerCase() === 'sas');\n"
    "    return all;"
)

# ── 3) Sett inn portal-hjelpere rett før buildMessage (om ikke finnes) ──
if "function bvIsTrumf" not in src:
    helpers = (
        "// ── Portal-bevisste hjelpere (SAS vs Trumf) ──\n"
        "function bvIsTrumf(c){ return String(c.source||'').toLowerCase()==='trumf'; }\n"
        "function bvOfferLink(c){ return c.url || c.link || (bvIsTrumf(c)?BV_TRUMF_HOME:(c.slug?BV_SAS_BASE+c.slug:BV_SAS_HOME)); }\n"
        "function bvPortalLabel(c){ return bvIsTrumf(c)?'Trumf':'SAS'; }\n"
        "function bvPoints(c){ return (c.raw&&c.raw.points_campaign)||c.points_campaign||c.points||c.rate||0; }\n"
        "function bvEndsTxt(c){ return (c.raw&&c.raw.campaign_ends_date)||(c.campaign_ends_iso?bvFmtDate(c.campaign_ends_iso):''); }\n"
        "function bvCardName(c){ return c.title||c.name||(c.raw&&c.raw.name)||c.store||'Butikk'; }\n"
        "function bvCardImg(c){ return c.image_url||(c.raw&&c.raw.image_url)||''; }\n\n"
        "function buildMessage("
    )
    src = src.replace("function buildMessage(", helpers, 1)

# ── 4) Erstatt HELE buildMessage-kroppen (Telegram, portal-bevisst) ──
new_buildmsg = '''function buildMessage(sasOffers, trumfOffers, sasFavs, trumfFavs) {
  let msg = '🔔 *Bonusvarsler denne uken*\\n\\n';
  if (trumfOffers.length > 0) {
    const fav = trumfFavs && trumfFavs.length > 0 ? ' (dine favoritter)' : '';
    msg += `🟢 *Trumf Netthandel${fav}*\\n`;
    for (const c of trumfOffers) {
      const p = bvPoints(c); const pt = p ? `: ${p}p/100kr` : '';
      msg += `🏆 [${bvCardName(c)}](${bvOfferLink(c)})${pt}\\n`;
    }
    msg += '\\n';
  }
  if (sasOffers.length > 0) {
    const fav = sasFavs && sasFavs.length > 0 ? ' (dine favoritter)' : '';
    msg += `✈️ *SAS Online Shopping${fav}*\\n`;
    for (const c of sasOffers) {
      const p = bvPoints(c); const pt = p ? `: ${p}p/100kr` : '';
      const e = bvEndsTxt(c) ? ` (t.o.m. ${bvEndsTxt(c)})` : '';
      msg += `🏆 [${bvCardName(c)}](${bvOfferLink(c)})${pt}${e}\\n`;
    }
    msg += '\\n';
  }
  msg += '⚠️ *Husk:* Klikk deg inn og logg inn via portalen for å få poengene. Starter du direkte i butikken, registreres ingen bonus.';
  return msg;
}'''

# Finn buildMessage(...) { ... } og erstatt til og med matchende avslutning
start = src.index("function buildMessage(")
# finn slutt: første "\n}\n" etter "return msg;"
ret = src.index("return msg;", start)
end = src.index("\n}", ret) + 2
src = src[:start] + new_buildmsg + src[end:]

# ── 5) Patch bvOfferCard: portal-bevisst lenke + badge + knappetekst ──
# 5a: link-linja
src = src.replace(
    'const link=slug?(BV_SAS_BASE+slug):(c.url||c.link||"https://onlineshopping.flysas.com/nb-NO");',
    'const link=bvOfferLink(c);\n  const portal=bvPortalLabel(c);\n  const badgeBg=bvIsTrumf(c)?"#1F7A4D":BV.NAVY;'
)
# 5b: badge ved navnet
src = src.replace(
    '<div style="font-size:16px;font-weight:800;color:${BV.NAVY}">${name}</div>',
    '<div style="font-size:16px;font-weight:800;color:${BV.NAVY}">${name} <span style="background:${badgeBg};color:#fff;font-size:10px;font-weight:700;padding:2px 8px;border-radius:10px;vertical-align:middle">${portal}</span></div>'
)
# 5c: knappetekst Handle → Handle via {portal}
src = src.replace(">Handle &rarr;</a>", ">Handle via ${portal} &rarr;</a>")

with open("functions/index.js", "w", encoding="utf-8") as f:
    f.write(src)

print("✅ index.js patchet")
PYTHON

# Syntakssjekk
node --check "$TARGET" && echo "✅ node --check OK" || { echo "❌ Syntaksfeil – gjenoppretter backup"; cp "$TARGET".bak_portal_* "$TARGET" 2>/dev/null; exit 1; }

echo ""
echo "📋 Verifisering:"
grep -c "trumfnetthandel.no" "$TARGET" && echo "  ↑ Trumf-referanser"
grep -q "api/campaigns" "$TARGET" && echo "  ✅ Bruker /api/campaigns"
grep -q "Handle via" "$TARGET"     && echo "  ✅ Portal-knapper"
grep -q "logg inn via portalen" "$TARGET" && echo "  ✅ Innloggings-påminnelse (Telegram)"
