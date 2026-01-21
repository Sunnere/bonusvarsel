import "dotenv/config";
/**
 * LoyaltyKey collector for SAS OnlineShopping
 * - Auto-paginates using links.next
 * - Retries with backoff (429 / 5xx / network)
 * - Caches responses on disk (per-URL)
 * - Writes raw + normalized JSON to ./data
 * - Delta detection: writes ./data/changes.json (added/removed/updated)
 *
 * Usage:
 *   node scripts/collect-loyaltykey.mjs
 *   NO_CACHE=1 node scripts/collect-loyaltykey.mjs
 *
 * Optional env:
 *   API_BASE=https://onlineshopping.loyaltykey.com
 *   CHANNEL=SAS
 *   LANGUAGE=nb
 *   COUNTRY=no
 *   PER_PAGE=100
 */

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const API_BASE = process.env.API_BASE || "https://onlineshopping.loyaltykey.com";
const OUT_DIR = path.resolve("data");
const CACHE_DIR = path.join(OUT_DIR, ".cache");

const CHANNEL = process.env.CHANNEL || "SAS";
const LANGUAGE = process.env.LANGUAGE || "nb";
const COUNTRY = process.env.COUNTRY || "no";
const PER_PAGE = Number(process.env.PER_PAGE || 100);

const NO_CACHE = process.env.NO_CACHE === "1" || process.argv.includes("--no-cache");

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function sha1(input) {
  return crypto.createHash("sha1").update(input).digest("hex");
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function buildUrl(pathname, params = {}) {
  const url = new URL(pathname, API_BASE);

  for (const [k, v] of Object.entries(params)) {
    if (v === undefined || v === null || v === "") continue;
    url.searchParams.set(k, String(v));
  }

  // start på page=1 hvis ikke satt
  if (!url.searchParams.has("page")) url.searchParams.set("page", "1");

  return url.toString();
}
function cachePathForUrl(url) {
  const key = sha1(url);
  return path.join(CACHE_DIR, `${key}.json`);
}

async function fetchJsonWithCache(url, { maxRetries = 6 } = {}) {
  ensureDir(CACHE_DIR);

  const cacheFile = cachePathForUrl(url);
  if (!NO_CACHE && fs.existsSync(cacheFile)) {
    try {
      const cached = JSON.parse(fs.readFileSync(cacheFile, "utf8"));
      if (cached && cached.data) return cached.data;
    } catch {
      // ignore broken cache
    }
  }

  let attempt = 0;
  let lastErr = null;

  while (attempt <= maxRetries) {
    attempt += 1;
    try {
      const res = await fetch(url, {
        headers: {
          "User-Agent": "Mozilla/5.0",
          "Accept": "application/json,text/plain,*/*",
        },
      });

      if (res.status === 429 || (res.status >= 500 && res.status <= 599)) {
        const retryAfter = res.headers.get("retry-after");
        const base = retryAfter ? Number(retryAfter) * 1000 : 400 * Math.pow(2, attempt);
        const jitter = Math.floor(Math.random() * 200);
        const wait = Math.min(10_000, base + jitter);
        await sleep(wait);
        continue;
      }

      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status} ${res.statusText} for ${url}\n${text.slice(0, 500)}`);
      }

      const data = await res.json();

      if (!NO_CACHE) {
        fs.writeFileSync(
          cacheFile,
          JSON.stringify({ savedAt: new Date().toISOString(), url, status: res.status, data }, null, 2)
        );
      }


      return data;
    } catch (e) {
      lastErr = e;
      const base = 300 * Math.pow(2, attempt);
      const jitter = Math.floor(Math.random() * 200);
      const wait = Math.min(8_000, base + jitter);
      await sleep(wait);
    }
  }

  throw lastErr || new Error(`Failed fetching ${url}`);
}

async function fetchAllPages(firstUrl) {
  const pages = [];
  let url = firstUrl;
  let pageCount = 0;

  const toAbsoluteUrl = (u) => {
    if (!u) return null;
    if (/^https?:\/\//i.test(u)) return u;
    const base = API_BASE.endsWith("/") ? API_BASE : API_BASE + "/";
    const p = u.startsWith("/") ? u.slice(1) : u;
    return new URL(p, base).toString();
  };

  url = toAbsoluteUrl(url);

  while (url) {
    pageCount += 1;

    const json = await fetchJsonWithCache(url);
    pages.push(json);

    const next = json?.links?.next;
    url = toAbsoluteUrl(next);

    if (pageCount > 200) throw new Error("Pagination safety stop: >200 pages");
  }

  return pages;
}
function flattenData(pages) {
  const all = [];
  for (const p of pages) {
    if (Array.isArray(p?.data)) all.push(...p.data);
  }
  return all;
}

function parseNorDate(ddmmyyyy) {
  if (!ddmmyyyy || typeof ddmmyyyy !== "string") return null;
  const m = ddmmyyyy.match(/^(\d{2})\.(\d{2})\.(\d{4})$/);
  if (!m) return null;
  const [, dd, mm, yyyy] = m;
  return `${yyyy}-${mm}-${dd}`;
}

function normalizeCampaign(c) {
  return {
    uuid: c.uuid ?? null,
    name: c.name ?? null,
    slug: c.slug ?? null,
    categoryId: c.categoryId ?? null,
    commission_type: c.commission_type ?? null,
    points: c.points ?? null,
    points_campaign: c.points_campaign ?? null,
    has_campaign: c.has_campaign ?? null,
    campaign_ends_date: c.campaign_ends_date ?? null,
    campaign_ends_iso: parseNorDate(c.campaign_ends_date),
    image_url: c.image_url ?? null,
    image_banner_url: c.image_banner_url ?? null,
  };
}

function normalizeShop(s) {
  return {
    uuid: s.uuid ?? null,
    name: s.name ?? null,
    slug: s.slug ?? null,
    categoryId: s.categoryId ?? null,
    commission_type: s.commission_type ?? null,
    currency: s.currency ?? null,
    points: s.points ?? null,
    points_channel: s.points_channel ?? null,
    has_campaign: s.has_campaign ?? null,
    points_campaign: s.points_campaign ?? null,
    campaign_ends_date: s.campaign_ends_date ?? null,
    campaign_ends_iso: parseNorDate(s.campaign_ends_date),
    image_url: s.image_url ?? null,
    image_banner_url: s.image_banner_url ?? null,
    logo: s.logo ?? null,
    background_image: s.background_image ?? null,
    has_shop_form: s.has_shop_form ?? null,
  };
}

function writeJson(file, obj) {
  ensureDir(OUT_DIR);
  fs.writeFileSync(path.join(OUT_DIR, file), JSON.stringify(obj, null, 2));
}

function readJsonIfExists(file) {
  const p = path.join(OUT_DIR, file);
  if (!fs.existsSync(p)) return null;
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return null;
  }
}

function indexByUuid(arr) {
  const m = new Map();
  for (const item of arr || []) {
    if (item && item.uuid) m.set(item.uuid, item);
  }
  return m;
}

function shallowDiff(oldObj, newObj) {
  const changed = {};
  const keys = new Set([...Object.keys(oldObj || {}), ...Object.keys(newObj || {})]);
  for (const k of keys) {
    const a = oldObj?.[k];
    const b = newObj?.[k];
    if (JSON.stringify(a) !== JSON.stringify(b)) {
      changed[k] = { from: a ?? null, to: b ?? null };
    }
  }
  return changed;
}

function computeChanges(prevArr, nextArr) {
  const prev = prevArr || [];
  const next = nextArr || [];
  const prevMap = indexByUuid(prev);
  const nextMap = indexByUuid(next);

  const added = [];
  const removed = [];
  const updated = [];

  for (const [uuid, nextItem] of nextMap.entries()) {
    const prevItem = prevMap.get(uuid);
    if (!prevItem) {
      added.push(nextItem);
      continue;
    }
    const diff = shallowDiff(prevItem, nextItem);
    if (Object.keys(diff).length > 0) {
      updated.push({
        uuid,
        name: nextItem.name ?? prevItem.name ?? null,
        slug: nextItem.slug ?? prevItem.slug ?? null,
        changes: diff,
      });
    }
  }

  for (const [uuid, prevItem] of prevMap.entries()) {
    if (!nextMap.has(uuid)) removed.push(prevItem);
  }

  // Stable ordering
  added.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
  removed.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
  updated.sort((a, b) => (a.name || "").localeCompare(b.name || ""));

  return {
    summary: {
      added: added.length,
      removed: removed.length,
      updated: updated.length,
      unchanged: Math.max(0, next.length - added.length - updated.length),
      prevTotal: prev.length,
      nextTotal: next.length,
    },
    added,
    removed,    updated,
  };
}

async function main() {
  ensureDir(OUT_DIR);

const commonParams = {
   "filter[channel]": CHANNEL,
   "filter[language]": LANGUAGE,
   "filter[country]": COUNTRY,
   per_page: PER_PAGE,
   page: 1,
};

  const startedAt = new Date().toISOString();

  // Read previous normalized snapshots (for delta)
  const prevCampaignsNorm = readJsonIfExists("campaigns.normalized.json") || [];
  const prevShopsNorm = readJsonIfExists("shops.normalized.json") || [];

  console.log(`API_BASE: ${API_BASE}`);
  console.log(`Params: channel=${CHANNEL} language=${LANGUAGE} country=${COUNTRY} per_page=${PER_PAGE}`);
  console.log(`Cache: ${NO_CACHE ? "OFF" : "ON"} (${CACHE_DIR})`);

  console.log("\nFetching campaigns…");
  const campaignsFirst = buildUrl("/api/v1/campaigns", {
  ...commonParams,
  "filter[amount]": 5,
  });
  const campaignPages = await fetchAllPages(campaignsFirst);
  const campaigns = flattenData(campaignPages);
  console.log(`Campaigns: ${campaigns.length} (${campaignPages.length} page(s))`);

  console.log("\nFetching shops…");
  const shopsFirst = buildUrl("/api/v1/shops", commonParams);
  const shopPages = await fetchAllPages(shopsFirst);
  const shops = flattenData(shopPages);
  console.log(`Shops: ${shops.length} (${shopPages.length} page(s))`);

  const campaignsNorm = campaigns.map(normalizeCampaign);
  const shopsNorm = shops.map(normalizeShop);

  // Write snapshots
  writeJson("campaigns.raw.json", {
    fetchedAt: startedAt,
    apiBase: API_BASE,
    params: commonParams,
    pages: campaignPages.length,
    data: campaigns,
  });
  writeJson("campaigns.normalized.json", campaignsNorm);

  writeJson("shops.raw.json", {
    fetchedAt: startedAt,
    apiBase: API_BASE,
    params: commonParams,
    pages: shopPages.length,
    data: shops,
  });
  writeJson("shops.normalized.json", shopsNorm);

  // Delta detection
  const campaignChanges = computeChanges(prevCampaignsNorm, campaignsNorm);
  const shopChanges = computeChanges(prevShopsNorm, shopsNorm);

  writeJson("changes.json", {
    startedAt,
    finishedAt: new Date().toISOString(),
    apiBase: API_BASE,
    params: commonParams,
    campaigns: campaignChanges,
    shops: shopChanges,
  });
  
  // Run metadata
   // Run metadata
  const finishedAt = new Date().toISOString();
  writeJson("lastRun.json", {
    startedAt,
    finishedAt,
    apiBase: API_BASE,
    params: commonParams,
    counts: {
      campaigns: campaigns.length,
      shops: shops.length,
      campaignPages: campaignPages.length,
      shopPages: shopPages.length,
    },
    cache: {
      enabled: !NO_CACHE,
      dir: CACHE_DIR,
    },
    deltas: {
      campaigns: campaignChanges.summary,
      shops: shopChanges.summary,
    },
  });


  console.log("\nDelta ✅");
  console.log(`Campaigns: +${campaignChanges.summary.added} / -${campaignChanges.summary.removed} / ~${campaignChanges.summary.updated}`);
  console.log(`Shops:     +${shopChanges.summary.added} / -${shopChanges.summary.removed} / ~${shopChanges.summary.updated}`);
function pick(obj, keys) {
}
const changesSummary = {
  campaigns: campaignChanges.summary,
  shops: shopChanges.summary,
};

fs.writeFileSync(
  path.join(OUT_DIR, "changes.summary.json"),
  JSON.stringify(changesSummary, null, 2),
  "utf-8"
);

// Write summary file (compact summary for notifications etc.)
  fs.writeFileSync(
    path.join(OUT_DIR, "changes.summary.json"),
    JSON.stringify(
      {
        campaigns: campaignChanges.summary,
        shops: shopChanges.summary,
      },
      null,
      2
    ),
    "utf-8"
  );

  console.log("\nDone ✅");
  console.log(`Wrote:
- data/campaigns.raw.json
- data/campaigns.normalized.json
- data/shops.raw.json
- data/shops.normalized.json
- data/changes.json
- data/changes.summary.json
- data/lastRun.json`);
}

main().catch((err) => {
  console.error("\nCollector failed ❌");
  console.error(err?.stack || err);
  process.exit(1);
});

