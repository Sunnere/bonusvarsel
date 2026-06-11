import dotenv from 'dotenv';
import sgMail from '@sendgrid/mail';
dotenv.config();

if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
  console.log('✅ SendGrid klar');
}

import express from "express";
import cors from "cors";
import fetch from "node-fetch";
import * as cheerio from "cheerio";


// ── E-post sending via SendGrid ───────────────────────────────────────────────
async function sendEmail(to, subject, html) {
  if (!process.env.SENDGRID_API_KEY || !process.env.SENDGRID_FROM) {
    console.warn('SendGrid ikke konfigurert');
    return false;
  }
  try {
    await sgMail.send({
      to,
      from: process.env.SENDGRID_FROM,
      subject,
      html,
    });
    console.log(`E-post sendt til ${to}`);
    return true;
  } catch (e) {
    console.error('SendGrid feil:', e?.response?.body || String(e));
    return false;
  }
}

// ── Telegram sending ─────────────────────────────────────────────────────────
const TG_BOT_TOKEN = process.env.TG_BOT_TOKEN || '';
const TG_CHAT_ID = process.env.TG_CHAT_ID || '';

async function sendTelegram(message) {
  if (!TG_BOT_TOKEN || !TG_CHAT_ID) {
    console.warn('Telegram ikke konfigurert');
    return false;
  }
  try {
    const url = `https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage`;
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: TG_CHAT_ID,
        text: message,
        parse_mode: 'HTML',
      }),
    });
    const data = await r.json();
    return data.ok;
  } catch (e) {
    console.error('Telegram feil:', e);
    return false;
  }
}


const app = express();

const port = Number(process.env.PORT || 8080);
const enableDevRoutes = process.env.ENABLE_DEV_ROUTES === "true";
const appVersion = process.env.APP_VERSION || "dev-local";
const autoPipelineIntervalMs = Number(process.env.AUTO_PIPELINE_INTERVAL_MS || 60000);
let currentAutoPipelineThreshold = Number(process.env.AUTO_PIPELINE_THRESHOLD || 2);
const autoDispatchMinMultiplier = Number(process.env.AUTO_DISPATCH_MIN_MULTIPLIER || 3);
const autoDispatchMinScore = Number(process.env.AUTO_DISPATCH_MIN_SCORE || 18);
const autoDispatchMaxPerTick = Number(process.env.AUTO_DISPATCH_MAX_PER_TICK || 2);

app.use(cors());
app.use(express.json({ limit: "256kb" }));

const state = {
  tier: "premium",
  devices: [
    {
      id: "device-demo-1",
      token: "flutter-demo-token",
      platform: "web",
      createdAt: new Date().toISOString(),
    },
  ],
  activatedNotifications: [],
  seededOffers: [],
  pipeline: {
    scanStatus: "idle",
    queueStatus: "idle",
    dispatchStatus: "idle",
    scanned: 0,
    queued: 0,
    dispatched: 0,
    lastSimulationId: null,
    lastUpdated: null,
    source: "none",
    summary: "Ingen simulering kjørt ennå.",
    recentCampaigns: [],
  },
  sentCampaignKeys: new Set(),
  lastGoodCampaigns: [],
  lastGoodCampaignsAt: null,
  lastFetchMode: "none",
  lastLiveSuccessAt: null,
  lastUpstreamError: null,
  tickCount: 0,
};

function nowIso() {
  return new Date().toISOString();
}

function buildPipelineState() {
  return {
    ok: true,
    scanStatus: state.pipeline.scanStatus,
    queueStatus: state.pipeline.queueStatus,
    dispatchStatus: state.pipeline.dispatchStatus,
    pipeline: {
      scanned: state.pipeline.scanned,
      queued: state.pipeline.queued,
      dispatched: state.pipeline.dispatched,
    },
    lastSimulationId: state.pipeline.lastSimulationId,
    lastUpdated: state.pipeline.lastUpdated,
    summary: state.pipeline.summary,
    threshold: currentAutoPipelineThreshold,
    source: state.pipeline.source,
    recentCampaigns: state.pipeline.recentCampaigns,
    notifications: {
      count: state.activatedNotifications.length,
      items: state.activatedNotifications,
    },
  };
}

async function fetchCampaigns() {
  const apiUrl =
    "https://onlineshopping.loyaltykey.com/api/v1/campaigns?filter[channel]=SAS&filter[language]=nb&filter[country]=NO&filter[amount]=20";

  try {
    const response = await fetch(apiUrl, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Accept": "application/json, text/plain, */*",
      },
    });

    if (!response.ok) {
      throw new Error(`LoyaltyKey campaigns failed: ${response.status}`);
    }

    const payload = await response.json();
    const rawItems = Array.isArray(payload?.data) ? payload.data : [];

    const mapped = rawItems
      .map((item, index) => {
        const title = item?.name ?? item?.title ?? `campaign-${index + 1}`;
        const slug = item?.slug ?? null;

        const basePoints = Number(item?.points ?? 0);
        const campaignPoints = Number(item?.points_campaign ?? 0);

        let multiplier = null;
        if (
          Number.isFinite(basePoints) &&
          Number.isFinite(campaignPoints) &&
          basePoints > 0 &&
          campaignPoints > 0
        ) {
          multiplier = Number((campaignPoints / basePoints).toFixed(2));
        }

        if (!Number.isFinite(multiplier) || multiplier <= 0) {
          multiplier = null;
        }

        const url = slug
          ? `https://onlineshopping.flysas.com/nb-NO/butikk/${slug}`
          : null;

        return {
          id: item?.uuid ?? `campaign-${index + 1}`,
          title: String(title),
          multiplier,
          url,
          slug,
          raw: item,
        };
      })
      .filter((item) => item.title && item.multiplier != null);

    console.log("fetchCampaigns LoyaltyKey mapped:", mapped.length);

    return mapped;
  } catch (e) {
    console.error("fetchCampaigns LoyaltyKey failed:", String(e));
    return [];
  }
}

function resetState() {
  state.activatedNotifications = [];
  state.seededOffers = [];
  state.sentCampaignKeys = new Set();
  state.lastGoodCampaigns = [];
  state.lastGoodCampaignsAt = null;
  state.lastFetchMode = "none";
  state.lastLiveSuccessAt = null;
  state.lastUpstreamError = null;
  state.tickCount = 0;
  state.pipeline = {
    scanStatus: "idle",
    queueStatus: "idle",
    dispatchStatus: "idle",
    scanned: 0,
    queued: 0,
    dispatched: 0,
    lastSimulationId: null,
    lastUpdated: nowIso(),
    source: "reset",
    summary: "Tilstand nullstilt.",
    recentCampaigns: [],
  };
}


function campaignKey(item) {
  return `${item.url || "no-url"}::${item.title || "untitled"}`;
}

function evaluateCampaign(item, reqBody = {}) {
  const baseRate = Number(item.multiplier || reqBody.rate || 0);
  const threshold = Number(reqBody.threshold || reqBody.alertThreshold || prefs?.alertThreshold || currentAutoPipelineThreshold || 2);

  const score = Math.round(baseRate * 7);
  const momentum =
    baseRate >= 15 ? "high" : baseRate >= 8 ? "medium" : "low";
  const timing = "now";
  const shouldNotify = baseRate >= threshold;

  const reason = shouldNotify
    ? `Rate ${baseRate} >= threshold ${threshold}`
    : `Rate ${baseRate} < threshold ${threshold}`;

  return {
    score,
    momentum,
    timing,
    shouldNotify,
    reason,
    threshold,
    rate: baseRate,
  };
}


// ── Trumf Netthandel kampanjer ────────────────────────────────────────────────
async function fetchTrumfCampaigns() {
  // Trumf Netthandel - oppdatert juni 2026
  // Disse endrer seg sjelden - oppdater manuelt ved behov
  const stores = [
    { title: 'Gina Tricot', slug: 'gina-tricot', points: 60, multiplier: 6 },
    { title: 'Outnorth', slug: 'outnorth', points: 50, multiplier: 5 },
    { title: 'SmartBuyGlasses', slug: 'smartbuyglasses', points: 80, multiplier: 8 },
    { title: 'Blivakker', slug: 'blivakker', points: 30, multiplier: 3 },
    { title: 'Lyko', slug: 'lyko', points: 40, multiplier: 4 },
    { title: 'Holdit', slug: 'holdit', points: 40, multiplier: 4 },
    { title: 'XXL', slug: 'xxl', points: 30, multiplier: 3 },
    { title: 'Komplett', slug: 'komplett', points: 20, multiplier: 2 },
    { title: 'Elkjøp', slug: 'elkjop', points: 10, multiplier: 1 },
    { title: 'Scandic', slug: 'scandic', points: 50, multiplier: 5 },
    { title: 'Nordic Nest', slug: 'nordic-nest', points: 40, multiplier: 4 },
  ];
  return stores
    .filter(s => s.multiplier > 1)
    .map(s => ({ ...s, id: s.slug, source: 'trumf', url: `https://trumfnetthandel.no/butikk/${s.slug}` }));
}


// ── Kombiner alle kampanjer med abonnement-filtrering ────────────────────────
async function fetchAllCampaigns(plan = 'free') {
  const [sasCampaigns, trumfCampaigns] = await Promise.all([
    fetchCampaigns(),
    fetchTrumfCampaigns(),
  ]);

  const all = [
    ...sasCampaigns.map(c => ({ ...c, source: 'sas', minPlan: 'free' })),
    ...trumfCampaigns.map(c => ({ ...c, source: 'trumf', minPlan: 'free' })),
  ];

  // Filtrer på abonnement
  const planLevel = { free: 0, premium: 1, elite: 2 };
  const userLevel = planLevel[plan] ?? 0;

  return all
    .filter(c => (planLevel[c.minPlan] ?? 0) <= userLevel)
    .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0));
}

async function runSimulation(reqBody = {}) {
  const simulationId = `sim-${Date.now()}`;
  const campaigns = await fetchCampaigns();
  const seeded = state.seededOffers.map((offer, i) => ({
    id: `seeded-${i + 1}`,
    title: `${offer.title} (${offer.store})`,
    multiplier: offer.rate,
    url: null,
  }));

  const combined = [...seeded, ...campaigns]
    .sort((a, b) => (Number(b.multiplier || 0) - Number(a.multiplier || 0)))
    .slice(0, 20);

  const evaluated = combined.map((item) => {
    const evaluation = evaluateCampaign(item, reqBody);
    return {
      ...item,
      evaluation,
      dedupeKey: campaignKey(item),
    };
  });

  // I dev-modus: nullstill dedup så vi alltid ser varsler
  if (reqBody.devMode !== false) state.sentCampaignKeys = new Set();

  const shouldNotifyItems = evaluated.filter((item) => item.evaluation.shouldNotify);
  const deduped = shouldNotifyItems.filter((item) => !state.sentCampaignKeys.has(item.dedupeKey));

  const scanned = combined.length;
  const queued = Math.min(deduped.length, 5);
  const dispatchable = deduped.slice(0, queued);
  const dispatchedItems = dispatchable.slice(0, 3);

  state.activatedNotifications = dispatchedItems.map((item, i) => ({
    id: `${simulationId}-notification-${i + 1}`,
    title: item.title,
    rate: item.multiplier ?? reqBody.rate ?? 18,
    level: reqBody.level ?? "premium",
    campaign: reqBody.campaign ?? true,
    activatedAt: nowIso(),
    shouldNotify: item.evaluation.shouldNotify,
    reason: item.evaluation.reason,
    score: item.evaluation.score,
    momentum: item.evaluation.momentum,
    timing: item.evaluation.timing,
  }));

  for (const item of dispatchedItems) {
    state.sentCampaignKeys.add(item.dedupeKey);
  }

  const dispatched = dispatchedItems.length;

  state.pipeline = {
    scanStatus: scanned > 0 ? "healthy" : "idle",
    queueStatus: queued > 0 ? "queued" : "idle",
    dispatchStatus: dispatched > 0 ? "dispatching" : "idle",
    scanned,
    queued,
    dispatched,
    lastSimulationId: simulationId,
    lastUpdated: nowIso(),
    source: seeded.length > 0 ? "seeded+live" : "sas-live",
    summary: `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • queued=${queued} • dispatched=${dispatched}`,
    recentCampaigns: prioritized.slice(0, 5).map((item) => ({
      title: item.title,
      multiplier: item.multiplier,
      url: item.url,
      shouldNotify: item.evaluation.shouldNotify,
      dispatchEligible:
        String(item.raw?.commission_type || '').toLowerCase() == 'fixed' ||
        Number(item.multiplier || 0) >= autoDispatchMinMultiplier ||
        Number(item.evaluation?.score || 0) >= autoDispatchMinScore,
      reason: item.evaluation.reason,
      score: item.evaluation.score,
      commissionType: item.raw?.commission_type ?? null,
    })),
  };

  return {
    ok: true,
    id: simulationId,
    source: state.pipeline.source,
    pipeline: {
      scanned,
      queued,
      dispatched,
    },
    notifications: {
      count: state.activatedNotifications.length,
      items: state.activatedNotifications,
    },
    recentCampaigns: state.pipeline.recentCampaigns,
    summary: state.pipeline.summary,
  };
}

app.get("/health", (_, res) => {
  res.json({
    ok: true,
    api: "up",
    version: appVersion,
    devRoutesEnabled: enableDevRoutes,
    pipeline: buildPipelineState(),
  });
});

app.get("/version", (_, res) => {
  res.json({
    ok: true,
    version: appVersion,
    devRoutesEnabled: enableDevRoutes,
  });
});

app.get("/api/campaigns", async (_, res) => {
  try {
    const campaigns = await fetchAllCampaigns();
    const trumfCamps = campaigns.filter(c => c.source === 'trumf');
    const sasCamps = campaigns.filter(c => c.source !== 'trumf');
    res.json({
      source: "combined",
      count: campaigns.length,
      trumfCount: trumfCamps.length,
      sasCount: sasCamps.length,
      campaigns,
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});
app.get("/api/debug", async (_, res) => {
  try {
    const url = "https://onlineshopping.flysas.com/nb-NO/kampanjer/1";
    const r = await fetch(url, {
      headers: { "User-Agent": "BonusVarsel/1.0 (Codespaces)" },
    });

    const html = await r.text();
    const $ = cheerio.load(html);

    const scripts = [];
    $("script").each((_, s) => {
      const src = $(s).attr("src");
      if (src) scripts.push(src);
    });

    const links = [];
    $("link").each((_, l) => {
      const href = $(l).attr("href");
      if (href) links.push(href);
    });

    const foundKeywords = [];
    const hay = html.toLowerCase();
    const needles = ["api", "json", "graphql", "campaign", "kampanj", "offers", "prom"];
    for (const n of needles) {
      if (hay.includes(n)) foundKeywords.push(n);
    }

    res.json({
      status: r.status,
      url,
      scripts: scripts.slice(0, 80),
      links: links.slice(0, 80),
      foundKeywords,
      htmlSnippet: html.slice(0, 2000),
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.post("/dev/simulate-campaign", async (req, res) => {
  try {
    const result = await runSimulation(req.body ?? {});
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.post("/v1/dev/simulate-campaign", async (req, res) => {
  try {
    const result = await runSimulation(req.body ?? {});
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});



app.post("/v1/push/simulate-alert", express.json(), (req, res) => {
  const now = new Date().toISOString();

  const rate = req.body?.rate ?? 10;

  const result = {
    simulatedAt: now,
    offer: {
      rate,
      rateText: rate + "x",
      level: rate >= 10 ? "premium" : "basic",
      campaign: "Simulated campaign"
    },
    evaluation: {
      score: Math.round(rate * 7),
      momentum: rate > 5 ? 3 : 1,
      timing: "now",
      shouldNotify: rate >= 8,
      reason: rate >= 8
        ? "High value campaign → should notify"
        : "Too low value → skip"
    }
  };

  // Lagre i state og send til Telegram
  if (result.evaluation.shouldNotify) {
    const slug = req.body?.slug || 'butikk';
    const tgMsg = `🔔 <b>${result.offer.rateText} bonus hos ${slug}</b>\n${result.evaluation.reason}\n\nScore: ${result.evaluation.score}`;
    sendTelegram(tgMsg).catch(e => console.error('Telegram feil:', e));
    state.activatedNotifications = [{
      id: `sim-${Date.now()}`,
      title: `${result.offer.rateText} bonus hos ${req.body?.slug || 'butikk'}`,
      rate: result.offer.rate,
      level: result.offer.level,
      activatedAt: result.simulatedAt,
      shouldNotify: true,
      reason: result.evaluation.reason,
      score: result.evaluation.score,
      momentum: result.evaluation.momentum,
      slug: req.body?.slug || 'outnorth',
      message: result.evaluation.reason,
    }];
  }

  res.json(result);
});


async function evaluateLivePipelineTick() {
  state.tickCount += 1;

  const simulationId = `auto-${Date.now()}`;
  let campaigns = [];
  let usedCache = false;
  let fetchError = null;

  try {
    campaigns = await fetchCampaigns();

    if (Array.isArray(campaigns) && campaigns.length > 0) {
      state.lastGoodCampaigns = campaigns;
      state.lastGoodCampaignsAt = nowIso();
      state.lastLiveSuccessAt = state.lastGoodCampaignsAt;
      state.lastUpstreamError = null;
    } else if (Array.isArray(state.lastGoodCampaigns) && state.lastGoodCampaigns.length > 0) {
      campaigns = state.lastGoodCampaigns;
      usedCache = true;
    }
  } catch (e) {
    fetchError = String(e);
    state.lastUpstreamError = fetchError;
    if (Array.isArray(state.lastGoodCampaigns) && state.lastGoodCampaigns.length > 0) {
      campaigns = state.lastGoodCampaigns;
      usedCache = true;
    } else {
      campaigns = [];
    }
  }

  const sorted = [...campaigns]
    .sort((a, b) => Number(b.multiplier || 0) - Number(a.multiplier || 0))
    .slice(0, 20);

  const evaluated = sorted.map((item) => {
    const evaluation = evaluateCampaign(item, {
      threshold: Number(currentAutoPipelineThreshold || 2),
      level: "premium",
      campaign: true,
    });

    return {
      ...item,
      evaluation,
      dedupeKey: campaignKey(item),
    };
  });

  const prioritized = [...evaluated].sort((a, b) => {
    const finalNotifyA = a.evaluation.shouldNotify == true ? 1 : 0;
    const finalNotifyB = b.evaluation.shouldNotify == true ? 1 : 0;
    if (finalNotifyB != finalNotifyA) return finalNotifyB - finalNotifyA;

    const fixedA =
      String(a.raw?.commission_type || '').toLowerCase() == 'fixed' ? 1 : 0;
    const fixedB =
      String(b.raw?.commission_type || '').toLowerCase() == 'fixed' ? 1 : 0;
    if (fixedB != fixedA) return fixedB - fixedA;

    const finalMultiplierA = Number(a.multiplier || 0);
    const finalMultiplierB = Number(b.multiplier || 0);
    if (finalMultiplierB != finalMultiplierA) return finalMultiplierB - finalMultiplierA;

    const finalScoreA = Number(a.evaluation.score || 0);
    const finalScoreB = Number(b.evaluation.score || 0);
    if (finalScoreB != finalScoreA) return finalScoreB - finalScoreA;

    return String(a.title || '').localeCompare(String(b.title || ''));
  });

  const shouldNotifyItems = prioritized.filter((item) => item.evaluation.shouldNotify);

  const dispatchCandidates = shouldNotifyItems.filter((item) => {
    const multiplier = Number(item.multiplier || 0);
    const score = Number(item.evaluation?.score || 0);
    const commissionType = String(item.raw?.commission_type || '').toLowerCase();

    return (
      commissionType == 'fixed' ||
      multiplier >= autoDispatchMinMultiplier ||
      score >= autoDispatchMinScore
    );
  });

  const deduped = dispatchCandidates.filter(
    (item) => !state.sentCampaignKeys.has(item.dedupeKey),
  );

  const seenTitles = new Set();
  const uniqueDispatchCandidates = deduped.filter((item) => {
    const titleKey = String(item.title || '').trim().toLowerCase();
    if (!titleKey) return true;
    if (seenTitles.has(titleKey)) return false;
    seenTitles.add(titleKey);
    return true;
  });

  const scanned = sorted.length;
  const queued = Math.min(uniqueDispatchCandidates.length, autoDispatchMaxPerTick);
  const dispatchable = uniqueDispatchCandidates.slice(0, queued);
  const dispatchedItems = dispatchable.slice(0, autoDispatchMaxPerTick);

  state.activatedNotifications = dispatchedItems.map((item, i) => ({
    id: `${simulationId}-notification-${i + 1}`,
    title: item.title,
    body: `${item.multiplier ?? 0}x poeng • ${item.evaluation.reason ?? 'Sterk kampanje'}`,
    rate: item.multiplier ?? 0,
    level: "premium",
    campaign: true,
    activatedAt: nowIso(),
    shouldNotify: item.evaluation.shouldNotify,
    reason: item.evaluation.reason,
    score: item.evaluation.score,
    momentum: item.evaluation.momentum,
    timing: item.evaluation.timing,
    url: item.url ?? null,
    slug: item.slug ?? null,
    commissionType: item.raw?.commission_type ?? null,
  }));

  for (const item of dispatchedItems) {
    state.sentCampaignKeys.add(item.dedupeKey);
  }

  const dispatched = dispatchedItems.length;
  const source = usedCache ? "live-feed-cache" : "live-feed-auto";
  state.lastFetchMode = source;
  if (!usedCache) {
    state.lastUpstreamError = null;
  }

  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • dispatchCandidates=${dispatchCandidates.length} • uniqueDispatchCandidates=${uniqueDispatchCandidates.length} • queued=${queued} • dispatched=${dispatched}`;
  if (usedCache) {
    summary += ` • cacheAt=${state.lastGoodCampaignsAt ?? "-"}`;
  }
  if (fetchError) {
    summary += ` • upstreamError=${fetchError}`;
  }

  state.pipeline = {
    scanStatus: scanned > 0 ? "healthy" : (fetchError ? "degraded" : "idle"),
    queueStatus: queued > 0 ? "queued" : "idle",
    dispatchStatus: dispatched > 0 ? "dispatching" : "idle",
    scanned,
    queued,
    dispatched,
    lastSimulationId: simulationId,
    lastUpdated: nowIso(),
    source,
    summary,
    threshold: currentAutoPipelineThreshold,
    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
    recentCampaigns: evaluated.slice(0, 5).map((item) => ({
      title: item.title,
      multiplier: item.multiplier,
      url: item.url,
      shouldNotify: item.evaluation.shouldNotify,
      reason: item.evaluation.reason,
      score: item.evaluation.score,
    })),
  };

  return {
    ok: fetchError == null || usedCache,
    source: state.pipeline.source,
    pipeline: {
      scanned,
      queued,
      dispatched,
    },
    usedCache,
    fetchError,
    lastGoodCampaignsAt: state.lastGoodCampaignsAt,
    threshold: currentAutoPipelineThreshold,
    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
  };
}

function startAutoPipeline() {
  if (!enableDevRoutes) return;

  evaluateLivePipelineTick()
    .then((result) => {
      console.log("Auto pipeline initial tick:", result);
    })
    .catch((e) => {
      console.error("Auto pipeline initial tick failed:", e);
    });

  setInterval(async () => {
    try {
      const result = await evaluateLivePipelineTick();
      console.log("Auto pipeline tick:", result);
    } catch (e) {
      console.error("Auto pipeline tick failed:", e);
    }
  }, autoPipelineIntervalMs);
}



if (enableDevRoutes) {
  startAutoPipeline();
}


app.get("/v1/dev/debug-campaign-fetch", async (_, res) => {
  try {
    const campaigns = await fetchCampaigns();
    res.json({
      ok: true,
      count: Array.isArray(campaigns) ? campaigns.length : 0,
      items: Array.isArray(campaigns) ? campaigns.slice(0, 10) : [],
    });
  } catch (e) {
    res.status(500).json({
      ok: false,
      error: String(e),
    });
  }
});


app.get("/v1/dev/debug-loyaltykey-raw", async (_, res) => {
  const apiUrl =
    "https://onlineshopping.loyaltykey.com/api/v1/campaigns?filter[channel]=SAS&filter[language]=nb&filter[country]=NO&filter[amount]=20";

  try {
    const response = await fetch(apiUrl, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Accept": "application/json, text/plain, */*",
      },
    });

    const rawText = await response.text();

    let parsed = null;
    let parseError = null;
    try {
      parsed = JSON.parse(rawText);
    } catch (e) {
      parseError = String(e);
    }

    const rawItems = Array.isArray(parsed)
      ? parsed
      : Array.isArray(parsed?.data)
          ? parsed.data
          : Array.isArray(parsed?.campaigns)
              ? parsed.campaigns
              : Array.isArray(parsed?.items)
                  ? parsed.items
                  : [];

    const first = rawItems[0] ?? null;

    let mappedFirst = null;
    if (first) {
      const title =
        first?.name ??
        first?.title ??
        first?.headline ??
        first?.shop_name ??
        first?.shopName ??
        "campaign-1";

      const slug = first?.slug ?? null;

      const rawUrl =
        first?.url ??
        first?.link ??
        first?.shop_url ??
        first?.shopUrl ??
        first?.tracking_url ??
        first?.trackingUrl ??
        (slug ? `https://onlineshopping.flysas.com/nb-NO/butikk/${slug}` : null);

      const basePoints = Number(first?.points ?? 0);
      const campaignPoints = Number(first?.points_campaign ?? 0);

      let multiplier = null;
      if (
        Number.isFinite(basePoints) &&
        Number.isFinite(campaignPoints) &&
        basePoints > 0 &&
        campaignPoints > 0
      ) {
        multiplier = Number((campaignPoints / basePoints).toFixed(2));
      }

      if (!Number.isFinite(multiplier) || multiplier <= 0) {
        multiplier = null;
      }

      mappedFirst = {
        title,
        slug,
        rawUrl,
        basePoints,
        campaignPoints,
        multiplier,
      };
    }

    res.json({
      ok: true,
      status: response.status,
      contentType: response.headers.get("content-type"),
      parseError,
      topLevelType: Array.isArray(parsed) ? "array" : typeof parsed,
      topLevelKeys:
        parsed && !Array.isArray(parsed) && typeof parsed === "object"
          ? Object.keys(parsed)
          : [],
      rawItemsCount: Array.isArray(rawItems) ? rawItems.length : 0,
      firstRawItem: first,
      firstMappedItem: mappedFirst,
      rawPreview: rawText.slice(0, 800),
    });
  } catch (e) {
    res.status(500).json({
      ok: false,
      error: String(e),
    });
  }
});



app.get("/v1/dev/auto-pipeline-threshold", (_, res) => {
  res.json({
    ok: true,
    threshold: currentAutoPipelineThreshold,
  });
});

app.post("/v1/dev/auto-pipeline-threshold", express.json(), (req, res) => {
  const next = Number(req.body?.threshold);

  if (!Number.isFinite(next) || next <= 0) {
    return res.status(400).json({
      ok: false,
      error: "threshold must be a positive number",
    });
  }

  currentAutoPipelineThreshold = next;

  state.pipeline = {
    ...state.pipeline,
    threshold: currentAutoPipelineThreshold,
    lastUpdated: nowIso(),
    summary: `${state.pipeline?.summary ?? "threshold updated"} • threshold=${currentAutoPipelineThreshold}`,
  };

  return res.json({
    ok: true,
    threshold: currentAutoPipelineThreshold,
  });
});



app.post("/v1/push/dispatch", express.json(), async (req, res) => {
  try {
    const { message, title, type } = req.body || {};
    const text = message || title || 'Test varsel fra Bonusvarsel';
    const ok = await sendTelegram(`🔔 <b>${title || 'Bonusvarsel'}</b>\n${text}`);
    res.json({ ok, sent: ok, channel: 'telegram' });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.post("/v1/push/test", express.json(), async (req, res) => {
  try {
    const email = req.body?.email || null;
    const tgOk = await sendTelegram('🧪 <b>Test varsel</b>\nDette er en test fra Bonusvarsel Dev Hub!');
    let emailOk = false;
    if (email) {
      emailOk = await sendEmail(
        email,
        '🧪 Test varsel fra Bonusvarsel',
        '<h2>Test varsel</h2><p>Dette er en test fra Bonusvarsel Dev Hub!</p>'
      );
    }
    res.json({ ok: tgOk, sent: tgOk, emailSent: emailOk });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});


// ── Push queue endpoints ──────────────────────────────────────────────────────
const pushQueue = [];

app.get("/v1/push/queue", (req, res) => {
  res.json({ ok: true, queue: pushQueue, count: pushQueue.length });
});

app.post("/v1/push/queue/process", express.json(), async (req, res) => {
  try {
    const items = pushQueue.splice(0, pushQueue.length);
    let sent = 0;
    for (const item of items) {
      const ok = await sendTelegram(`🔔 <b>${item.title || 'Bonusvarsel'}</b>\n${item.message || ''}`);
      if (ok) sent++;
    }
    res.json({ ok: true, processed: items.length, sent, result: 'done', items });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.post("/v1/push/enqueue-test", express.json(), async (req, res) => {
  try {
    const item = { title: 'Test varsel', message: 'Dette er en test fra Bonusvarsel!', ts: Date.now() };
    pushQueue.push(item);
    const ok = await sendTelegram(`🧪 <b>${item.title}</b>\n${item.message}`);
    res.json({ ok: true, sent: ok, queued: pushQueue.length });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});


// ── Devices endpoint ─────────────────────────────────────────────────────────
const registeredDevices = [];

app.get("/v1/devices", (req, res) => {
  res.json(registeredDevices);
});

app.post("/v1/devices", express.json(), (req, res) => {
  const device = req.body || {};
  device.registeredAt = new Date().toISOString();
  const existing = registeredDevices.findIndex(d => d.deviceId === device.deviceId);
  if (existing >= 0) {
    registeredDevices[existing] = device;
  } else {
    registeredDevices.push(device);
  }
  res.json({ ok: true, device });
});

// ── Send test endpoint ────────────────────────────────────────────────────────
app.post("/v1/push/send-test", express.json(), async (req, res) => {
  try {
    const { title, message, slug } = req.body || {};
    const text = `🔔 <b>${title || 'Test varsel'}</b>\n${message || 'Dette er et test-varsel fra Bonusvarsel!'}${slug ? '\n\nButikk: ' + slug : ''}`;
    const ok = await sendTelegram(text);
    res.json({ ok, sent: ok, channel: 'telegram', sentAt: new Date().toISOString() });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});


// ── Notifications endpoint ────────────────────────────────────────────────────
app.get("/v1/notifications/activated", (req, res) => {
  const notifications = state.activatedNotifications || [];
  res.json({
    ok: true,
    count: notifications.length,
    items: notifications,
    lastUpdated: state.pipeline?.lastUpdated || null,
  });
});

app.get("/v1/notifications/activated/elite", (req, res) => {
  const notifications = state.activatedNotifications || [];
  res.json({
    ok: true,
    count: notifications.length,
    items: notifications,
  });
});

// ── Push preview endpoint ─────────────────────────────────────────────────────
app.get("/v1/push/preview", (req, res) => {
  const notifications = state.activatedNotifications || [];
  res.json({
    ok: true,
    previews: notifications.map(n => ({
      title: n.title || 'Bonusvarsel',
      message: n.message || n.reason || 'Kampanje tilgjengelig',
      slug: n.slug,
      score: n.evaluation?.score || 0,
    })),
  });
});

// ── Seed offers endpoint ──────────────────────────────────────────────────────
app.post("/v1/offers", express.json(), (req, res) => {
  const offer = req.body || {};
  offer.id = `offer-${Date.now()}`;
  offer.createdAt = new Date().toISOString();
  state.seededOffers = state.seededOffers || [];
  state.seededOffers.push(offer);
  res.json({ ok: true, offer, total: state.seededOffers.length });
});

app.get("/v1/offers", (req, res) => {
  res.json({
    ok: true,
    offers: state.seededOffers || [],
    count: (state.seededOffers || []).length,
  });
});


app.get("/v1/push/dispatch", (req, res) => {
  const dispatches = state.activatedNotifications || [];
  res.json({
    ok: true,
    count: dispatches.length,
    dispatches: dispatches.map(n => ({
      id: n.id || `dispatch-${Date.now()}`,
      title: n.title || 'Bonusvarsel',
      message: n.message || n.reason || 'Kampanje tilgjengelig',
      slug: n.slug,
      score: n.evaluation?.score || 0,
      sentAt: n.sentAt || new Date().toISOString(),
      channel: 'telegram',
    })),
  });
});


// ── Device favorites ─────────────────────────────────────────────────────────
const deviceFavorites = {};

app.post("/v1/devices/favorites", express.json(), (req, res) => {
  const { trumf = [], sas = [], email = null } = req.body || {};
  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf, sas, email, updatedAt: new Date().toISOString() };
  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumf.length}, SAS=${sas.length}, Email=${email || 'ingen'}`);
  res.json({ ok: true, trumf: trumf.length, sas: sas.length });
});

app.get("/v1/devices/favorites", (req, res) => {
  res.json({ ok: true, devices: deviceFavorites });
});



async function checkFavoritesAndNotify() {
  try {
    const campaigns = await fetchCampaigns();
    if (!campaigns.length) return;

    for (const [deviceId, favs] of Object.entries(deviceFavorites)) {
      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      if (!allFavSlugs.length) continue;

      // Samle alle nye kampanjer i en liste
      const newCampaigns = [];
      for (const campaign of campaigns) {
        if (!campaign.slug) continue;
        // Normaliser - appen bruker tn_outnorth, API returnerer outnorth
        const normalizedFavSlugs = allFavSlugs.map(s => 
          s.replace(/^tn_/, '').replace(/^sas_/, ''));
        const normalizedCampaignSlug = campaign.slug.replace(/^tn_/, '').replace(/^sas_/, '');
        if (!normalizedFavSlugs.includes(normalizedCampaignSlug)) continue;
        if ((campaign.multiplier ?? 1) <= 1) continue;
        const key = `${deviceId}-${campaign.slug}-${campaign.multiplier}`;
        if (state.sentCampaignKeys.has(key)) continue;
        newCampaigns.push(campaign);
        state.sentCampaignKeys.add(key);
      }

      if (!newCampaigns.length) continue;

      // Send én samlet melding
      const lines = newCampaigns
        .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
        .map(c => `• ${c.title}: ${c.multiplier}x bonus`)
        .join('\n');

      const msg = newCampaigns.length === 1
        ? `🔔 <b>${newCampaigns[0].title}</b> har ${newCampaigns[0].multiplier}x bonus akkurat nå!\n\nÅpne Bonusvarsel og gå til butikken via appen for å tjene ekstra poeng.`
        : `🔔 <b>${newCampaigns.length} favorittbutikker har kampanje!</b>\n\n${lines}\n\nÅpne Bonusvarsel for å handle og tjene ekstra poeng.`;

      const tgOk = await sendTelegram(msg);

      // Send e-post
      if (favs.email) {
        const htmlLines = newCampaigns
          .sort((a,b) => (b.multiplier??0)-(a.multiplier??0))
          .map(c => `<li><b>${c.title}</b>: ${c.multiplier}x bonus</li>`)
          .join('');
        const htmlMsg = newCampaigns.length === 1
          ? `<h2>🔔 ${newCampaigns[0].title} har ${newCampaigns[0].multiplier}x bonus akkurat nå!</h2><p>Åpne Bonusvarsel og gå til butikken via appen for å tjene ekstra poeng.</p>`
          : `<h2>🔔 ${newCampaigns.length} favorittbutikker har kampanje!</h2><ul>${htmlLines}</ul><p>Åpne Bonusvarsel for å handle og tjene ekstra poeng.</p>`;
        await sendEmail(
          favs.email,
          '🔔 Bonusvarsel – kampanje hos favorittene dine!',
          htmlMsg
        );
      }

      if (tgOk) console.log(`Varsel sendt: ${newCampaigns.length} kampanjer til ${favs.email || 'ingen email'}`);
    }
  } catch (e) {
    console.error('checkFavoritesAndNotify feil:', String(e));
  }
}

app.post("/dev/check-favorites", async (req, res) => {
  await checkFavoritesAndNotify();
  res.json({ ok: true, devices: Object.keys(deviceFavorites).length });
});


app.post("/dev/reset-sent-keys", (req, res) => {
  state.sentCampaignKeys = new Set();
  res.json({ ok: true, message: "sentCampaignKeys nullstilt" });
});

app.listen(port, () => {
  console.log(`API running on http://127.0.0.1:${port}`);
  console.log(`DEV routes enabled: ${enableDevRoutes}`);
});
