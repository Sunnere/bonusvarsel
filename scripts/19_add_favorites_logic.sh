#!/bin/bash
set -e
TARGET="scripts/build-tier-messages.mjs"
cp "$TARGET" "$TARGET.bak_favs_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

cat > "$TARGET" << 'MJS'
// scripts/build-tier-messages.mjs
// Bygger tier-meldinger med favoritt-støtte
// Eksporterer buildForUser(plan, favs) for Firebase
import fs from "node:fs";
import path from "node:path";
import { getInsightForShop } from "./history-insights.mjs";

const DATA_DIR = process.env.DATA_DIR || "data";
const PROGRAM_NAME = process.env.DISPLAY_NAME || "SAS EuroBonus";
const TODAY = new Date().toISOString().slice(0, 10);

function readJson(p) {
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, "utf8")); }
  catch { return null; }
}

const campaigns = readJson(path.join(DATA_DIR, "campaigns.normalized.json")) || [];
const activeCampaigns = campaigns
  .filter(c => c.has_campaign === 1 && c.points_campaign > 0)
  .filter(c => !c.campaign_ends_iso || c.campaign_ends_iso >= TODAY)
  .sort((a, b) => b.points_campaign - a.points_campaign);
const totalCount = activeCampaigns.length;

function fmtDate(iso) {
  if (!iso) return "";
  const [y, m, d] = iso.split("-");
  return `${d}.${m}`;
}

// Filtrer kampanjer på brukerens favoritter (matcher navn/slug)
function filterByFavs(campaigns, favs) {
  if (!favs || favs.length === 0) return [];
  return campaigns.filter(c =>
    favs.some(f =>
      c.name.toLowerCase().includes(f.toLowerCase()) ||
      c.slug.toLowerCase().includes(f.toLowerCase())
    )
  );
}

// ── FREE: kun antall ──────────────────────────────
export function buildFree() {
  let msg = `🔔 *Bonusvarsel – ${PROGRAM_NAME}*\n\n`;
  msg += `📦 ${totalCount} aktive kampanjer denne uken!\n\n`;
  if (activeCampaigns.length > 0) {
    msg += `🔒 Topptilbud akkurat nå:\n`;
    msg += `• ${activeCampaigns[0].name} – skjult 🔒\n`;
    if (activeCampaigns[1]) msg += `• ${activeCampaigns[1].name} – skjult 🔒\n`;
  }
  msg += `\n💎 *Oppgrader til Premium* for å se alle tilbud!\n`;
  msg += `👉 Åpne Bonusvarsel-appen`;
  return msg;
}

// ── PREMIUM: favoritter eller nyeste + info ───────
export function buildPremium(favs = []) {
  const favMatches = filterByFavs(activeCampaigns, favs);
  const hasFavs = favMatches.length > 0;
  let msg = `💙 *PREMIUM – ${PROGRAM_NAME}*\n\n`;

  if (hasFavs) {
    msg += `⭐ *Dine favoritter denne uken:*\n\n`;
    for (const c of favMatches.slice(0, 5)) {
      const ends = c.campaign_ends_iso ? ` (t.o.m. ${fmtDate(c.campaign_ends_iso)})` : "";
      const normal = c.points > 0 ? ` ${c.points}p →` : "";
      msg += `🏆 *${c.name}*:${normal} ${c.points_campaign}p/100kr${ends}\n`;
    }
    msg += `\n👉 Handle via Bonusvarsel-appen`;
  } else {
    const picks = activeCampaigns.slice(0, 3);
    msg += `📦 *Siden du ikke har valgt favoritter, får du ukens ${picks.length} nyeste kampanjer:*\n\n`;
    for (const c of picks) {
      const ends = c.campaign_ends_iso ? ` (t.o.m. ${fmtDate(c.campaign_ends_iso)})` : "";
      const normal = c.points > 0 ? ` ${c.points}p →` : "";
      msg += `🏆 *${c.name}*:${normal} ${c.points_campaign}p/100kr${ends}\n`;
    }
    msg += `\n💡 *Tips:* Velg opptil 5 favorittbutikker i appen for å slippe varsler fra butikker du ikke handler i!\n`;
    msg += `👉 Åpne Bonusvarsel → Varsler → Velg favoritter`;
  }
  return msg;
}

// ── ELITE: favoritter + historikk, eller nyeste + info ──
export function buildElite(favs = [], nivapoeng = null) {
  const favMatches = filterByFavs(activeCampaigns, favs);
  const hasFavs = favMatches.length > 0;
  let msg = `👑 *ELITE – ${PROGRAM_NAME}*\n\n`;

  const picks = hasFavs ? favMatches.slice(0, 10) : activeCampaigns.slice(0, 4);

  if (!hasFavs) {
    msg += `📦 *Siden du ikke har valgt favoritter, får du ukens ${picks.length} nyeste kampanjer:*\n\n`;
  } else {
    msg += `⭐ *Dine favoritter med smart innsikt:*\n\n`;
  }

  for (const c of picks) {
    const ends = c.campaign_ends_iso ? ` (t.o.m. ${fmtDate(c.campaign_ends_iso)})` : "";
    const normal = c.points > 0 ? ` ${c.points}p →` : "";
    msg += `🏆 *${c.name}*:${normal} ${c.points_campaign}p/100kr${ends}\n`;
    const insight = getInsightForShop(c.slug, c.points_campaign);
    if (insight) {
      msg += `   ${insight.headline}\n`;
      msg += `   💡 ${insight.recommendation}\n`;
    }
    msg += `\n`;
  }

  if (!hasFavs) {
    msg += `💡 *Tips:* Velg opptil 10 favorittbutikker for skreddersydde varsler!\n`;
    msg += `👉 Åpne Bonusvarsel → Varsler → Velg favoritter\n\n`;
  }

  msg += `👉 Eksklusiv innsikt fra Bonusvarsel Elite`;
  return msg;
}

// Skriv standard-versjoner til fil (uten favoritter)
const output = {
  generatedAt: new Date().toISOString(),
  program: PROGRAM_NAME,
  totalCount,
  free: buildFree(),
  premium: buildPremium([]),
  elite: buildElite([]),
};

const outPath = path.join(DATA_DIR, "tier-messages.json");
fs.writeFileSync(outPath, JSON.stringify(output, null, 2) + "\n", "utf8");
console.log(`✅ Tier-meldinger bygget → ${outPath}`);
console.log(`   Free: ${output.free.length} tegn`);
console.log(`   Premium: ${output.premium.length} tegn`);
console.log(`   Elite: ${output.elite.length} tegn`);
MJS
echo "✅ build-tier-messages.mjs oppdatert med favoritt-logikk"
