#!/bin/bash
# Script 28 – Portal-bevisst e-post og Telegram i api/server.js
# Patcher checkFavoritesAndNotify() med per-tilbud Trumf/SAS portal-lenker

set -e
cd /Users/sunnerehelse/bonusvarsel

echo "📦 Script 28 – Portal-lenker i e-post & Telegram"
echo ""

# Backup
cp api/server.js api/server.js.bak28
echo "✅ Backup: api/server.js.bak28"

# Patch via Node
node << 'NODE'
const fs = require('fs');
const file = 'api/server.js';
let src = fs.readFileSync(file, 'utf8');

const helperCode = `

// ── Portal-hjelpefunksjoner (script 28) ──────────────────────────────────────
const SAS_BASE   = "https://onlineshopping.flysas.com/nb-NO/butikk/";
const SAS_HOME   = "https://onlineshopping.flysas.com/nb-NO";
const TRUMF_HOME = "https://trumfnetthandel.no";

function bvOfferLink(c) {
  if (c.source === 'trumf') return TRUMF_HOME;
  if (c.source === 'elite') return c.url || SAS_HOME;
  if (c.slug) return SAS_BASE + c.slug;
  return SAS_HOME;
}
function bvPortalLabel(c) {
  return c.source === 'trumf' ? 'Trumf Netthandel' : 'SAS Online Shopping';
}
function bvPortalColor(c) {
  return c.source === 'trumf' ? '#1F7A4D' : '#0F2340';
}
function bvOfferCard(c) {
  const link  = bvOfferLink(c);
  const label = bvPortalLabel(c);
  const color = bvPortalColor(c);
  const pts   = c.multiplier ? \`\${c.multiplier}x poeng per 100 kr\` : '';
  return \`<div style="background:#fff;border:1px solid #e5e7eb;border-radius:12px;padding:20px 24px;margin:12px 0;font-family:Arial,sans-serif;">
  <div style="display:inline-block;background:\${color};color:#fff;font-size:11px;font-weight:700;padding:3px 10px;border-radius:20px;margin-bottom:10px;letter-spacing:.5px;">\${label.toUpperCase()}</div>
  <div style="font-size:17px;font-weight:700;color:#111;">\${c.title}</div>
  \${pts ? \`<div style="color:#555;font-size:14px;margin-top:4px;">\${pts}</div>\` : ''}
  <a href="\${link}" style="display:inline-block;margin-top:14px;background:#D4AF37;color:#000;font-weight:700;padding:10px 22px;border-radius:8px;text-decoration:none;font-size:14px;">Handle via \${label} →</a>
</div>\`;
}
function bvTelegramLine(c) {
  const link  = bvOfferLink(c);
  const label = bvPortalLabel(c);
  const pts   = c.multiplier ? \`\${c.multiplier}x poeng\` : '';
  return \`🏆 <a href="\${link}">\${c.title}</a>\${pts ? ': ' + pts : ''} <i>via \${label}</i>\`;
}
const BV_EMAIL_REMINDER = \`<div style="background:#FFF8E1;border-left:4px solid #D4AF37;padding:14px 18px;margin:20px 0;border-radius:6px;font-family:Arial,sans-serif;"><b style="color:#7A5C00;">⚠️ Viktig!</b> <span style="color:#7A5C00;">Du må klikke deg inn og <b>logge inn via portalen</b> (Trumf Netthandel eller SAS Online Shopping) for å få poengene. Starter du direkte i butikken, registreres ingen bonus.</span></div>\`;
const BV_TG_REMINDER = \`⚠️ Husk: Klikk deg inn og logg inn via portalen for å få poengene. Starter du direkte i butikken, registreres ingen bonus.\`;
`;

if (!src.includes('bvOfferLink')) {
  const anchor = `}
}


const app = express();`;
  src = src.replace(anchor, helperCode + '\n\n' + anchor);
  console.log('✅ Portal-hjelpefunksjoner lagt til');
} else {
  console.log('ℹ️  Hjelpefunksjoner finnes allerede');
}

const oldLines = `      const lines = newCampaigns
        .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
        .map(c => \`• \${c.title}: \${c.multiplier}x bonus\`)
        .join('\\n');`;
if (src.includes(oldLines)) {
  src = src.replace(oldLines, `      // lines erstattet av bvTelegramLine (script 28)`);
  console.log('✅ Gammel lines-variabel fjernet');
}

const oldTgMsg = `      const msg = newCampaigns.length === 1
        ? \`🔔 <b>\${newCampaigns[0].title}</b> har \${newCampaigns[0].multiplier}x bonus akkurat nå!\\n\\nÅpne Bonusvarsel og gå til butikken via appen for å tjene ekstra poeng.\`
        : \`🔔 <b>\${newCampaigns.length} favorittbutikker har kampanje!</b>\\n\\n\${lines}\\n\\nÅpne Bonusvarsel for å handle og tjene ekstra poeng.\`;`;
const newTgMsg = `      const tgLines = newCampaigns
        .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
        .map(c => bvTelegramLine(c))
        .join('\\n');
      const msg = newCampaigns.length === 1
        ? \`🔔 <b>\${newCampaigns[0].title}</b> har \${newCampaigns[0].multiplier}x bonus akkurat nå!\\n\\n\${bvTelegramLine(newCampaigns[0])}\\n\\n\${BV_TG_REMINDER}\`
        : \`🔔 <b>\${newCampaigns.length} favorittbutikker har kampanje!</b>\\n\\n\${tgLines}\\n\\n\${BV_TG_REMINDER}\`;`;
if (src.includes(oldTgMsg)) {
  src = src.replace(oldTgMsg, newTgMsg);
  console.log('✅ Telegram oppdatert med portal-lenker');
} else {
  console.log('⚠️  ADVARSEL: Telegram-blokk ikke funnet');
}

const oldEmail = `        const htmlLines = newCampaigns
          .sort((a,b) => (b.multiplier??0)-(a.multiplier??0))
          .map(c => \`<li><b>\${c.title}</b>: \${c.multiplier}x bonus</li>\`)
          .join('');
        const htmlMsg = newCampaigns.length === 1
          ? \`<h2>🔔 \${newCampaigns[0].title} har \${newCampaigns[0].multiplier}x bonus akkurat nå!</h2><p>Åpne Bonusvarsel og gå til butikken via appen for å tjene ekstra poeng.</p>\`
          : \`<h2>🔔 \${newCampaigns.length} favorittbutikker har kampanje!</h2><ul>\${htmlLines}</ul><p>Åpne Bonusvarsel for å handle og tjene ekstra poeng.</p>\`;`;
const newEmail = `        const htmlCards = newCampaigns
          .sort((a,b) => (b.multiplier??0)-(a.multiplier??0))
          .map(c => bvOfferCard(c))
          .join('');
        const htmlMsg = \`<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 \${newCampaigns.length === 1 ? newCampaigns[0].title + ' har kampanje!' : newCampaigns.length + ' favorittbutikker har kampanje!'}</h2>\${htmlCards}\${BV_EMAIL_REMINDER}</div>\`;`;
if (src.includes(oldEmail)) {
  src = src.replace(oldEmail, newEmail);
  console.log('✅ E-post oppdatert med portal-kort og påminnelse');
} else {
  console.log('⚠️  ADVARSEL: E-post-blokk ikke funnet');
}

fs.writeFileSync(file, src, 'utf8');
console.log('\n✅ api/server.js lagret');
NODE

echo ""
echo "🧪 Syntakssjekk..."
node --check api/server.js && echo "✅ Syntaks OK" || {
  echo "❌ Syntaksfeil – gjenoppretter backup"
  cp api/server.js.bak28 api/server.js
  exit 1
}

echo ""
echo "📤 Deploy:"
echo "   git add api/server.js && git commit -m 'script28: Trumf→trumfnetthandel.no, SAS→per-butikk, innloggings-påminnelse' && git push"
