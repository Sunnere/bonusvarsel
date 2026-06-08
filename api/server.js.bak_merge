import express from "express";
import cors from "cors";
import fetch from "node-fetch";
import * as cheerio from "cheerio";

const app = express();
<<<<<<< Updated upstream
app.use(cors());

app.get("/health", (_, res) => res.json({ ok: true }));

app.get("/api/campaigns", async (_, res) => {
  try {
    const url = "https://onlineshopping.flysas.com/nb-NO/kampanjer/1";

    const r = await fetch(url, {
      headers: { "User-Agent": "BonusVarsel/1.0 (Codespaces)" }
    });

    if (!r.ok) {
      return res.status(502).json({ error: "Upstream error", status: r.status });
    }

    const html = await r.text();
    const $ = cheerio.load(html);

    const items = [];

    $("a").each((_, a) => {
      const href = $(a).attr("href") || "";
      const text = $(a).text().replace(/\s+/g, " ").trim();
      if (!text || text.length < 10) return;

      const absolute = href.startsWith("http")
        ? href
        : href.startsWith("/")
          ? `https://onlineshopping.flysas.com${href}`
          : `https://onlineshopping.flysas.com/${href}`;

      const lower = text.toLowerCase();
      const looksLikeCampaign =
        lower.includes("poeng") || lower.includes("bonus") || /(\d+\s*x)/i.test(text);

      if (!looksLikeCampaign) return;

      const m = text.match(/(\d+)\s*x/i);
      const multiplier = m ? Number(m[1]) : null;

      items.push({
        title: text,
        store: null,
        details: null,
        multiplier,
        url: absolute
      });
    });

    const seen = new Set();
    const campaigns = items
      .filter((x) => {
        const k = `${x.url}::${x.title}`;
        if (seen.has(k)) return false;
        seen.add(k);
        return true;
      })
      .slice(0, 50);

    res.json({ source: url, count: campaigns.length, campaigns });
=======

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
    const campaigns = await fetchCampaigns();
    res.json({
      source: "sas-live",
      count: campaigns.length,
      campaigns,
    });
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
=======
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
}



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
      momentum: rate > 5 ? "high" : "low",
      timing: "now",
      shouldNotify: rate >= 8,
      reason: rate >= 8
        ? "High value campaign → should notify"
        : "Too low value → skip"
    }
  };

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


app.listen(port, () => {
  console.log(`API running on http://127.0.0.1:${port}`);
  console.log(`DEV routes enabled: ${enableDevRoutes}`);
>>>>>>> Stashed changes
});
const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`API running on http://0.0.0.0:${port}`));
