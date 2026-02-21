#!/usr/bin/env node
// scripts/build-eb-shopping-assets.mjs
//
// Lager en lettvekts "EuroBonus Shopping"-feed som Flutter kan lese fra assets.
// Leser fra DATA_DIR (default: data) som kommer fra collector, og skriver til:
// - assets/eb.shopping.min.json
//
// Kjør:
//   node scripts/build-eb-shopping-assets.mjs
// Eller med spesifikk data:
//   DATA_DIR=data/sas node scripts/build-eb-shopping-assets.mjs

import fs from "node:fs";
import path from "node:path";

function mustReadJson(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Fant ikke fil: ${filePath}`);
  }
  const raw = fs.readFileSync(filePath, "utf8");
  try {
    return JSON.parse(raw);
  } catch (e) {
    const head = raw.slice(0, 120).replace(/\s+/g, " ");
    throw new Error(`Ugyldig JSON i ${filePath}. Starter med: "${head}"`);
  }
}

function asArray(x) {
  if (!x) return [];
  if (Array.isArray(x)) return x;
  if (Array.isArray(x.items)) return x.items;
  if (Array.isArray(x.data)) return x.data;
  if (Array.isArray(x.results)) return x.results;
  return [];
}

function safeStr(x) {
  return (x ?? "").toString().trim();
}

function safeNum(x) {
  const n = Number(x);
  return Number.isFinite(n) ? n : null;
}

function pickUrl(o) {
  return (
    safeStr(o.url) ||
    safeStr(o.trackingUrl) ||
    safeStr(o.tracking_url) ||
    safeStr(o.link) ||
    safeStr(o.href) ||
    ""
  );
}

function pickName(o) {
  return (
    safeStr(o.merchant) ||
    safeStr(o.title) ||
    safeStr(o.name) ||
    safeStr(o.shopName) ||
    safeStr(o.partnerName) ||
    "Ukjent"
  );
}

function pickId(o, fallback) {
  return (
    safeStr(o.id) ||
    safeStr(o.shopId) ||
    safeStr(o.shop_id) ||
    safeStr(o.merchantId) ||
    safeStr(o.merchant_id) ||
    safeStr(o.campaignId) ||
    safeStr(o.campaign_id) ||
    safeStr(o.slug) ||
    fallback
  );
}

// Multiplikator / poengrate – prøv flere felt
function pickRate(o) {
  return (
    safeNum(o.multiplier) ??
    safeNum(o.pointsPerKr) ??
    safeNum(o.points_per_kr) ??
    safeNum(o.pointsPerCurrency) ??
    safeNum(o.points_per_currency) ??
    safeNum(o.points) ??
    safeNum(o.rate) ??
    null
  );
}

function pickKind(o, fallback) {
  const k = safeStr(o.kind || o.type || "").toLowerCase();
  if (k.includes("campaign")) return "campaign";
  if (k.includes("shop")) return "shop";
  return fallback;
}

function uniqById(arr) {
  const seen = new Set();
  const out = [];
  for (const it of arr) {
    if (!it.id) continue;
    if (seen.has(it.id)) continue;
    seen.add(it.id);
    out.push(it);
  }
  return out;
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function main() {
  const DATA_DIR = String(process.env.DATA_DIR || "data").trim();
  const PROGRAM = safeStr(process.env.PROGRAM || "sas").toLowerCase();

  // Collector kan skrive enten til data/ (flat) eller data/<program>/
  // Vi støtter begge: hvis DATA_DIR peker til en mappe som allerede inneholder json, bruk den.
  // Hvis ikke, prøv data/<program>.
  let baseDir = path.resolve(DATA_DIR);
  const shopsPath1 = path.join(baseDir, "shops.normalized.json");
  const campaignsPath1 = path.join(baseDir, "campaigns.normalized.json");

  if (!fs.existsSync(shopsPath1) && !fs.existsSync(campaignsPath1)) {
    const alt = path.resolve("data", PROGRAM);
    const shopsPathAlt = path.join(alt, "shops.normalized.json");
    const campaignsPathAlt = path.join(alt, "campaigns.normalized.json");
    if (fs.existsSync(shopsPathAlt) || fs.existsSync(campaignsPathAlt)) {
      baseDir = alt;
    }
  }

  const shopsPath = path.join(baseDir, "shops.normalized.json");
  const campaignsPath = path.join(baseDir, "campaigns.normalized.json");

  const shopsRaw = fs.existsSync(shopsPath) ? mustReadJson(shopsPath) : [];
  const campsRaw = fs.existsSync(campaignsPath) ? mustReadJson(campaignsPath) : [];

  const shops = asArray(shopsRaw).map((o, idx) => {
    const id = pickId(o, `shop_${idx}`);
    const name = pickName(o);
    const url = pickUrl(o);
    const rate = pickRate(o);
    return {
      id,
      kind: pickKind(o, "shop"),
      name,
      rate,
      url,
    };
  });

  const campaigns = asArray(campsRaw).map((o, idx) => {
    const id = pickId(o, `camp_${idx}`);
    const name = pickName(o);
    const url = pickUrl(o);
    const rate = pickRate(o);
    const startsAt = safeStr(o.startsAt || o.start || o.startDate || o.start_date || "");
    const endsAt = safeStr(o.endsAt || o.end || o.endDate || o.end_date || "");
    return {
      id,
      kind: pickKind(o, "campaign"),
      name,
      rate,
      url,
      startsAt: startsAt || null,
      endsAt: endsAt || null,
    };
  });

  const out = {
    version: 1,
    generatedAt: new Date().toISOString(),
    program: PROGRAM,
    // Flutter skal være kjapp: bare det vi trenger i UI nå
    shops: uniqById(shops),
    campaigns: uniqById(campaigns),
  };

  const assetsDir = path.resolve("assets");
  ensureDir(assetsDir);

  const outPath = path.join(assetsDir, "eb.shopping.min.json");
  fs.writeFileSync(outPath, JSON.stringify(out), "utf8");

  console.log(`✅ Wrote: ${outPath}`);
  console.log(
    `   program=${PROGRAM} dir=${baseDir} shops=${out.shops.length} campaigns=${out.campaigns.length}`
  );
}

main();
