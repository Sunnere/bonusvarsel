#!/bin/bash
set -e
TARGET="scripts/archive-history.mjs"
echo "📦 Oppretter $TARGET ..."
cat > "$TARGET" << 'MJS'
// scripts/archive-history.mjs
import fs from "node:fs";
import path from "node:path";

const DATA_DIR = process.env.DATA_DIR || "data";
const HISTORY_DIR = path.join(DATA_DIR, "history");

function readJson(p) {
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, "utf8")); }
  catch { return null; }
}

const campaigns = readJson(path.join(DATA_DIR, "campaigns.normalized.json"));
if (!campaigns || !Array.isArray(campaigns)) {
  console.log("Ingen campaigns.normalized.json – hopper over");
  process.exit(0);
}

fs.mkdirSync(HISTORY_DIR, { recursive: true });
const today = new Date().toISOString().slice(0, 10);
const month = today.slice(0, 7);

const snapshot = campaigns
  .filter(c => c.has_campaign === 1 || c.points_campaign > 0)
  .map(c => ({
    slug: c.slug, name: c.name, points: c.points,
    points_campaign: c.points_campaign,
    campaign_ends_iso: c.campaign_ends_iso || null,
    categoryId: c.categoryId,
  }));

const dayPath = path.join(HISTORY_DIR, `${today}.json`);
fs.writeFileSync(dayPath, JSON.stringify({ date: today, count: snapshot.length, campaigns: snapshot }, null, 2) + "\n", "utf8");

const monthPath = path.join(HISTORY_DIR, `_month_${month}.json`);
const monthData = readJson(monthPath) || { month, shops: {} };
for (const c of snapshot) {
  if (!monthData.shops[c.slug]) {
    monthData.shops[c.slug] = { name: c.name, maxPoints: c.points_campaign, firstSeen: today, lastSeen: today };
  } else {
    const s = monthData.shops[c.slug];
    s.maxPoints = Math.max(s.maxPoints, c.points_campaign);
    s.lastSeen = today;
  }
}
fs.writeFileSync(monthPath, JSON.stringify(monthData, null, 2) + "\n", "utf8");
console.log(`✅ Arkivert ${snapshot.length} kampanjer til ${dayPath}`);
MJS
echo "✅ archive-history.mjs opprettet"
