#!/bin/bash
set -e

# ── DEL 1: Premium grønn skygge i e-post ──
TARGET="scripts/build-email-html.mjs"
cp "$TARGET" "$TARGET.bak_green_$(date +%Y%m%d_%H%M%S)"

python3 - << 'PYTHON'
with open('scripts/build-email-html.mjs', 'r') as f:
    content = f.read()

# Legg til Premium grønn farge + støtte for tre nivåer
old = 'const NAVY = "#0F2340", GOLD = "#D4AF37", ELITE_BG = "#110A28";'
new = 'const NAVY = "#0F2340", GOLD = "#D4AF37", ELITE_BG = "#110A28", PREMIUM_BG = "#0A1F14";'
content = content.replace(old, new)

# Oppdater header-logikk: free=navy, premium=grønn, elite=lilla
old2 = """export function buildEmailHtml(campaigns, tier = "Premium", isElite = false) {
  const headerBg = isElite ? ELITE_BG : NAVY;"""
new2 = """export function buildEmailHtml(campaigns, tier = "Premium", isElite = false) {
  // Farge per nivå: Gratis=navy, Premium=grønn, Elite=lilla luksus
  const tierLower = String(tier).toLowerCase();
  const headerBg = isElite ? ELITE_BG
    : tierLower.includes("premium") ? PREMIUM_BG
    : NAVY;"""
content = content.replace(old2, new2)

# Legg til Amex-disclaimer i footer
old3 = '''        <div style="color:#fff;font-size:12px;line-height:1.6">
          Du mottar dette fordi du har registrert e-posten i Bonusvarsel-appen.<br>
          <a href="mailto:support@bonusvarsel.no?subject=Avmeld" style="color:${GOLD}">Avmeld deg</a>
        </div>'''
new3 = '''        <div style="color:#fff;font-size:12px;line-height:1.6">
          Du mottar dette fordi du har registrert e-posten i Bonusvarsel-appen.<br>
          <a href="mailto:support@bonusvarsel.no?subject=Avmeld" style="color:${GOLD}">Avmeld deg</a>
        </div>
        <div style="color:#999;font-size:10px;line-height:1.5;margin-top:10px;border-top:1px solid rgba(255,255,255,0.1);padding-top:8px">
          «Premium» og «Elite» er Bonusvarsel sine egne abonnementsnivåer<br>
          og har ingen tilknytning til American Express sine kortprodukter.
        </div>'''
content = content.replace(old3, new3)

with open('scripts/build-email-html.mjs', 'w') as f:
    f.write(content)
print('✅ Premium grønn + Amex-disclaimer lagt til i e-post')
PYTHON

echo ""
echo "🧪 Bygger forhåndsvisning av alle tre nivåer..."
node -e "
import('./scripts/build-email-html.mjs').then(m => {
  const fs = require('fs');
  const c = JSON.parse(fs.readFileSync('data/campaigns.normalized.json'));
  const today = new Date().toISOString().slice(0,10);
  const active = c.filter(x=>x.has_campaign===1 && x.points_campaign>0)
    .filter(x=>!x.campaign_ends_iso || x.campaign_ends_iso>=today)
    .sort((a,b)=>b.points_campaign-a.points_campaign).slice(0,4);
  fs.writeFileSync('data/email-premium-preview.html', m.buildEmailHtml(active, 'Premium', false));
  fs.writeFileSync('data/email-elite-preview.html', m.buildEmailHtml(active, '👑 Elite', true));
  console.log('✅ Premium (grønn) + Elite (lilla) bygget');
});
"
