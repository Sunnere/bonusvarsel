#!/bin/bash
set -e
TARGET="scripts/build-tier-messages.mjs"
echo "📦 Oppretter $TARGET ..."
cat > "$TARGET" << 'MJS'
// scripts/build-tier-messages.mjs
import fs from "node:fs";
import path from "node:path";
import { getInsightForShop } from "./history-insights.mjs";

const DATA_DIR = process.env.DATA_DIR || "data";
const PROGRAM_NAME = process.env.DISPLAY_NAME || "SAS EuroBonus";

function readJson(p) {
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, "utf8")); }
  catch { return null; }
}

const campaigns = readJson(path.join(DATA_DIR, "campaigns.normalized.json")) || [];
const activeCampaigns = campaigns
  .filter(c => c.has_campaign === 1 && c.points_campaign > 0)
  .sort((a, b) => b.points_campaign - a.points_campaign);
const totalCount = activeCampaigns.length;

function fmtDate(iso) {
  if (!iso) return "";
  const [y, m, d] = iso.split("-");
  return `${d}.${m}`;
}

function buildFree() {
  let msg = `🔔 *Bonusvarsel – ${PROGRAM_NAME}*\n\n`;
  msg += `📦 ${totalCount} aktive kampanjer denne uken!\n\n`;
  if (activeCampaigns.length > 0) {
    msg += `🔒 Topptilbud akkurat nå:\n`;
    msg += `• ${activeCampaigns[0].name} – skjult 🔒\n`;
    if (activeCampaigns[1]) msg += `• ${activeCampaigns[1].name} – skjult 🔒\n`;
  }
  msg += `\n💎 *Oppgrader til Premium* for å se alle tilbud, poeng og utløpsdato!\n`;
  msg += `👉 Åpne Bonusvarsel-appen`;
  return msg;
}

function buildPremium(picks) {
  let msg = `🔔 *Bonusvarsel – ${PROGRAM_NAME}*\n\n`;
  msg += `💙 *${picks.length} utvalgte tilbud denne uken*\n\n`;
  for (const c of picks) {
    const ends = c.campaign_ends_iso ? ` (t.o.m. ${fmtDate(c.campaign_ends_iso)})` : "";
    const normal = c.points > 0 ? ` ${c.points}p →` : "";
    msg += `• *${c.name}*:${normal} ${c.points_campaign}p/100kr${ends}\n`;
  }
  msg += `\n👉 Handle via Bonusvarsel-appen`;
  return msg;
}

function buildElite(picks) {
  let msg = `👑 *ELITE – ${PROGRAM_NAME}*\n\n`;
  msg += `Dine smarte bonusvarsler denne uken:\n\n`;
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
  msg += `👉 Eksklusiv innsikt fra Bonusvarsel Elite`;
  return msg;
}

const premiumPicks = activeCampaigns.slice(0, 3);
const elitePicks = activeCampaigns.slice(0, 4);

const output = {
  generatedAt: new Date().toISOString(),
  program: PROGRAM_NAME,
  totalCount,
  free: buildFree(),
  premium: buildPremium(premiumPicks),
  elite: buildElite(elitePicks),
};

const outPath = path.join(DATA_DIR, "tier-messages.json");
fs.writeFileSync(outPath, JSON.stringify(output, null, 2) + "\n", "utf8");
console.log(`✅ Tier-meldinger bygget → ${outPath}`);
console.log(`   Free: ${output.free.length} tegn`);
console.log(`   Premium: ${output.premium.length} tegn (${premiumPicks.length} tilbud)`);
console.log(`   Elite: ${output.elite.length} tegn (${elitePicks.length} tilbud)`);
MJS
echo "✅ build-tier-messages.mjs opprettet"
