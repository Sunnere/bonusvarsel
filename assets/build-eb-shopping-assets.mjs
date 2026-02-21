// scripts/build-eb-shopping-assets.mjs
import fs from "node:fs";
import path from "node:path";

function readJson(p) {
  if (!fs.existsSync(p)) throw new Error(`Missing file: ${p}`);
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n", "utf8");
}

function pick(obj, keys) {
  for (const k of keys) {
    if (obj && obj[k] != null && obj[k] !== "") return obj[k];
  }
  return null;
}

function normStr(x) {
  return String(x ?? "").trim();
}

function normNum(x) {
  if (x == null) return null;
  const n = Number(x);
  return Number.isFinite(n) ? n : null;
}

function toKey(s) {
  return normStr(s).toLowerCase().replace(/\s+/g, " ").trim();
}

// --- INPUT (SAS / EuroBonus shopping fra LoyaltyKey collector) ---
const DATA_DIR = process.env.DATA_DIR || "data";
const shopsPath = path.resolve(DATA_DIR, "shops.normalized.json");
const campaignsPath = path.resolve(DATA_DIR, "campaigns.normalized.json");

const shops = readJson(shopsPath);
const campaigns = readJson(campaignsPath);

// shops.normalized.json kan være {items:[...]} eller [...]
const shopItems = Array.isArray(shops) ? shops : (shops?.items ?? []);
const campItems = Array.isArray(campaigns) ? campaigns : (campaigns?.items ?? []);

// 1) Lag index over kampanjer per merchant (best effort)
const campaignsByMerchant = new Map();

for (const c of campItems) {
  const merchant =
    pick(c, ["merchant", "merchantName", "shopName", "partnerName", "title"]) ??
    "";
  const merchantKey = toKey(merchant);
  if (!merchantKey) continue;

  const startsAt = pick(c, ["startsAt", "startDate", "starts_at", "start_at"]);
  const endsAt = pick(c, ["endsAt", "endDate", "ends_at", "end_at"]);

  const multiplier = normNum(pick(c, ["multiplier", "rate", "pointsPerKr", "points_per_kr"]));
  const title = pick(c, ["title", "heading", "name"]);
  const url = pick(c, ["url", "link", "landingUrl", "landing_url"]);

  const item = {
    title: normStr(title) || null,
    merchant: normStr(merchant) || null,
    multiplier,
    startsAt: startsAt ? String(startsAt) : null,
    endsAt: endsAt ? String(endsAt) : null,
    url: url ? String(url) : null,
  };

  const arr = campaignsByMerchant.get(merchantKey) ?? [];
  arr.push(item);
  campaignsByMerchant.set(merchantKey, arr);
}

// 2) Normaliser shops til app-format
function normalizeShop(s) {
  const merchant =
    pick(s, ["merchant", "merchantName", "name", "title", "shopName"]) ?? "";

  const url = pick(s, ["url", "link", "landingUrl", "landing_url", "shopUrl"]) ?? null;
  const multiplier = normNum(pick(s, ["multiplier", "rate", "pointsPerKr", "points_per_kr"]));
  const category = pick(s, ["category", "categoryName", "segment", "group"]) ?? null;

  // noen datasett har booleans / flags
  const isActive = Boolean(pick(s, ["active", "isActive", "enabled"]) ?? true);

  const merchantKey = toKey(merchant);
  const related = campaignsByMerchant.get(merchantKey) ?? [];

  // “boost” = hvis det finnes kampanje med multiplier høyere enn base shop multiplier
  const bestCampaign = related
    .filter(x => x && x.multiplier != null)
    .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))[0] ?? null;

  const boosted =
    bestCampaign?.multiplier != null &&
    (multiplier == null || bestCampaign.multiplier > multiplier);

  return {
    id: normStr(pick(s, ["id", "shopId", "merchantId", "slug"])) || merchantKey || null,
    merchant: normStr(merchant),
    url: url ? String(url) : null,
    multiplier,
    category: category ? String(category) : null,
    isActive,
    hasCampaign: related.length > 0,
    boosted,
    bestCampaign: bestCampaign
      ? {
          title: bestCampaign.title,
          multiplier: bestCampaign.multiplier,
          startsAt: bestCampaign.startsAt,
          endsAt: bestCampaign.endsAt,
          url: bestCampaign.url,
        }
      : null,
    program: "eurobonus",
    source: "sas-online-shopping",
  };
}

const allShops = shopItems
  .map(normalizeShop)
  .filter(s => s.merchant && s.merchant.length > 0);

// campaignsShops = butikker med kampanje/boost
const campaignShops = allShops.filter(s => s.hasCampaign || s.boosted);

// Sort: boosted først, så høyeste multiplier / bestCampaign.multiplier
function score(s) {
  const base = s.multiplier ?? 0;
  const boost = s.bestCampaign?.multiplier ?? 0;
  return Math.max(base, boost) + (s.boosted ? 10000 : 0) + (s.hasCampaign ? 1000 : 0);
}

campaignShops.sort((a, b) => score(b) - score(a));
allShops.sort((a, b) => (a.merchant || "").localeCompare(b.merchant || "", "nb"));

const out = {
  meta: {
    program: "eurobonus",
    source: "sas-online-shopping",
    builtAt: new Date().toISOString(),
    input: {
      dataDir: DATA_DIR,
      shopsPath: path.relative(process.cwd(), shopsPath),
      campaignsPath: path.relative(process.cwd(), campaignsPath),
    },
    counts: {
      allShops: allShops.length,
      campaignShops: campaignShops.length,
      campaigns: campItems.length,
    },
  },
  campaignShops,
  allShops,
};

const outPath = path.resolve("assets", "eb.shopping.json");
writeJson(outPath, out);

console.log(
  `✅ Wrote ${outPath}\nallShops=${allShops.length}, campaignShops=${campaignShops.length}, campaigns=${campItems.length}`
);
