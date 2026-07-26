
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
import * as sentKeysStore from './lib/sentKeysStore.js';
import * as telegramLinkStore from './lib/telegramLinkStore.js';
import * as telegramDeviceStore from './lib/telegramDeviceStore.js';
import { initMonitor, startMonitor, runMonitorCheck, monitorStatus } from './lib/monitor.js';


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
    console.error('SendGrid feil DETALJER:', JSON.stringify(e?.response?.body) || String(e));
    return false;
  }
}

// ── Telegram sending ─────────────────────────────────────────────────────────
const TG_BOT_TOKEN = process.env.TG_BOT_TOKEN || '';
const TG_CHAT_ID = process.env.TG_CHAT_ID || '';

async function sendTelegram(message, chatId = TG_CHAT_ID) {
  if (!TG_BOT_TOKEN || !chatId) {
    console.warn('Telegram ikke konfigurert (mangler bot-token eller chat_id)');
    return false;
  }
  try {
    const url = `https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage`;
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: 'HTML',
      }),
    });
    const data = await r.json();
    if (!data.ok) console.error('Telegram API avviste meldingen:', data);
    return data.ok;
  } catch (e) {
    console.error('Telegram feil:', e);
    return false;
  }
}

// ── Portal-hjelpefunksjoner (script 28) ──────────────────────────────────────
const SAS_BASE   = "https://onlineshopping.flysas.com/nb-NO/butikk/";
const SAS_HOME   = "https://onlineshopping.flysas.com/nb-NO";
const TRUMF_HOME = "https://trumfnetthandel.no";

function bvOfferLink(c) {
  if (c.source === 'trumf') return TRUMF_HOME;
  return SAS_HOME;
}
function bvPortalLabel(c) {
  return c.source === 'trumf' ? 'Trumf Netthandel' : 'SAS Online Shopping';
}
function bvPortalColor(c) {
  return c.source === 'trumf' ? '#1F7A4D' : '#0F2340';
}
function bvPointsText(c) {
  if (c.source === 'trumf') return 'ekstra Trumf-bonus nå';
  if (c.source === 'sas')   return 'ekstra EuroBonus-poeng nå';
  return 'kampanje nå';
}
function bvOfferCard(c) {
  const link  = bvOfferLink(c);
  const label = bvPortalLabel(c);
  const color = bvPortalColor(c);
  const pts   = bvPointsText(c);
  return `<div style="background:#fff;border:1px solid #e5e7eb;border-radius:12px;padding:20px 24px;margin:12px 0;font-family:Arial,sans-serif;">
  <div style="display:inline-block;background:${color};color:#fff;font-size:11px;font-weight:700;padding:3px 10px;border-radius:20px;margin-bottom:10px;letter-spacing:.5px;">${label.toUpperCase()}</div>
  <div style="font-size:17px;font-weight:700;color:#111;">${c.title}</div>
  ${pts ? `<div style="color:#555;font-size:14px;margin-top:4px;">${pts}</div>` : ''}
  <a href="${link}" style="display:inline-block;margin-top:14px;background:#D4AF37;color:#000;font-weight:700;padding:10px 22px;border-radius:8px;text-decoration:none;font-size:14px;">Handle via ${label} →</a>
</div>`;
}
function bvTelegramLine(c) {
  const link  = bvOfferLink(c);
  const label = bvPortalLabel(c);
  const pts   = bvPointsText(c);
  return `🏆 <a href="${link}">${c.title}</a>${pts ? ': ' + pts : ''} <i>via ${label}</i>`;
}
const BV_EMAIL_REMINDER = `<div style="background:#FFF8E1;border-left:4px solid #D4AF37;padding:14px 18px;margin:20px 0;border-radius:6px;font-family:Arial,sans-serif;"><b style="color:#7A5C00;">⚠️ Viktig!</b> <span style="color:#7A5C00;">Du må klikke deg inn og <b>logge inn via portalen</b> (Trumf Netthandel eller SAS Online Shopping) for å få poengene. Starter du direkte i butikken, registreres ingen bonus.</span></div>`;
const BV_TG_REMINDER = `⚠️ Husk: Klikk deg inn og logg inn via portalen for å få poengene. Starter du direkte i butikken, registreres ingen bonus.`;


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
// Ekte, live skraping av https://trumfnetthandel.no/kategori/ukens-tilbud (offentlig
// side, bekreftet tilgjengelig uten innlogging). Erstatter tidligere hardkodet
// fantasidata - "multiplier" her er butikkens gjeldende Trumf-bonusprosent
// (ikke nødvendigvis "ekstra denne uken vs normalen", men ekte og ferskt tall).
async function fetchTrumfCampaigns() {
  try {
    const response = await fetch("https://trumfnetthandel.no/kategori/ukens-tilbud", {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Accept": "text/html",
      },
    });

    if (!response.ok) {
      throw new Error(`Trumf Netthandel skraping feilet: ${response.status}`);
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    const mapped = [];
    $("#CategoryResults a.merchant-tile").each((_, el) => {
      const $el = $(el);
      const name = $el.attr("data-name");
      const percentageRaw = $el.attr("data-percentage") || "";
      const popularity = Number($el.attr("data-popularity") || 0);
      const href = $el.attr("href");
      if (!name || !href) return;

      const pctMatch = percentageRaw.match(/^([\d,]+)\s*%$/);
      if (!pctMatch) return;
      const multiplier = parseFloat(pctMatch[1].replace(",", "."));
      if (!Number.isFinite(multiplier) || multiplier <= 0) return;

      mapped.push({
        id: href,
        title: name,
        multiplier,
        url: `https://trumfnetthandel.no${href}`,
        slug: href.replace("/cashback/", ""),
        popularity,
      });
    });

    console.log("fetchTrumfCampaigns skrapet:", mapped.length, "butikker");
    return mapped;
  } catch (e) {
    console.error("fetchTrumfCampaigns feilet:", String(e));
    return [];
  }
}


// ── SAS Holidays / Elite-tilbud ──────────────────────────────────────────────
async function fetchEliteCampaigns() {
  const holidays = [
    {
      title: 'SAS Holidays: Spar 2 000 kr',
      desc: 'Bestill fly + hotell innen 22. juni',
      code: 'SUMMERDEAL',
      savings: '2000 kr',
      url: 'https://www.flysas.com/no-no/sas-holidays/',
      ends: '22.06.2026',
    },
  ];
  return holidays.map((h, i) => ({
    ...h,
    id: `elite-holiday-${i}`,
    source: 'elite',
  }));
}


// ── Kombiner alle kampanjer med abonnement-filtrering ────────────────────────
async function fetchAllCampaigns(plan = 'free') {
  const [sasCampaigns, trumfCampaigns, eliteCampaigns] = await Promise.all([
    fetchCampaigns(),
    fetchTrumfCampaigns(),
    fetchEliteCampaigns(),
  ]);

  const all = [
    ...sasCampaigns.map(c => ({ ...c, source: 'sas', minPlan: 'free' })),
    ...trumfCampaigns.map(c => ({ ...c, source: 'trumf', minPlan: 'free' })),
    ...eliteCampaigns.map(c => ({ ...c, source: 'elite', minPlan: 'elite' })),
  ];

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
    recentCampaigns: evaluated.slice(0, 5).map((item) => ({
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
    sentKeys: sentKeysStore.status(),
    monitor: monitorStatus(),
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
    const campaigns = await fetchAllCampaigns('elite');
    const trumfCamps = campaigns.filter(c => c.source === 'trumf');
    const sasCamps = campaigns.filter(c => c.source === 'sas');
    const eliteCamps = campaigns.filter(c => c.source === 'elite');
    res.json({
      source: "combined",
      count: campaigns.length,
      trumfCount: trumfCamps.length,
      sasCount: sasCamps.length,
      eliteCount: eliteCamps.length,
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
  const { trumf = [], sas = [], email = null, telegram = null, tier = 'free' } = req.body || {};
  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf, sas, email, telegram, tier, updatedAt: new Date().toISOString() };
  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumf.length}, SAS=${sas.length}, Email=${email || 'ingen'}, Telegram=${telegram || 'ingen'}, Tier=${tier}`);
  res.json({ ok: true, trumf: trumf.length, sas: sas.length });
});

// Telegram-webhook: fanger opp chat_id når en bruker starter/skriver til @bonusvarsel_bot,
// og kobler det til brukernavnet deres (kun slik kan vi senere sende dem private meldinger).
app.post("/telegram/webhook", express.json(), async (req, res) => {
  try {
    const msg = req.body && req.body.message;
    const username = msg && msg.from && msg.from.username;
    const chatId = msg && msg.chat && msg.chat.id;
    const text = (msg && msg.text) || '';
    let linked = false;

    const startMatch = text.match(/^\/start(?:@\w+)?\s+(\S+)/);
    if (startMatch && chatId) {
      const deviceId = startMatch[1];
      await telegramDeviceStore.set(deviceId, chatId);
      console.log(`[telegram/webhook] Koblet enhet ${deviceId} -> chat_id ${chatId}`);
      linked = true;
    }

    if (username && chatId) {
      await telegramLinkStore.set(username, chatId);
      console.log(`[telegram/webhook] Koblet @${username} -> chat_id ${chatId}`);
      linked = true;
    }

    if (linked) {
      await sendTelegram(
        '✅ Du er nå koblet til Bonusvarsel! Du vil motta varsler her når favorittene dine får kampanjer (eller ukens beste tilbud hvis du ikke har valgt noen).',
        chatId
      );
    }
  } catch (e) {
    console.error('[telegram/webhook] feil:', e);
  }
  res.sendStatus(200);
});

app.get("/v1/devices/favorites", (req, res) => {
  res.json({ ok: true, devices: deviceFavorites });
});



function osloNow() {
  return new Date(new Date().toLocaleString('en-US', { timeZone: 'Europe/Oslo' }));
}

function isWeeklyFallbackWindow() {
  const now = osloNow();
  return now.getDay() === 3 && now.getHours() === 18;
}

function weekKey() {
  const now = osloNow();
  const firstJan = new Date(now.getFullYear(), 0, 1);
  const week = Math.ceil((((now - firstJan) / 86400000) + firstJan.getDay() + 1) / 7);
  return `${now.getFullYear()}-W${week}`;
}

async function checkFavoritesAndNotify() {
  try {
    const campaigns = await fetchAllCampaigns('elite');
    console.log(`[CHECKFAV] campaigns=${campaigns.length} devices=${Object.keys(deviceFavorites).length}`);
    if (!campaigns.length) return;

    for (const [deviceId, favs] of Object.entries(deviceFavorites)) {
      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      const isFreeTier = !allFavSlugs.length;

      const newCampaigns = [];
      if (isFreeTier) {
        if (!isWeeklyFallbackWindow()) continue;
        const topGeneral = campaigns
          .filter(c => c.slug && (c.multiplier ?? 1) > 1)
          .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
          .slice(0, 2);
        for (const campaign of topGeneral) {
          const key = `${deviceId}-weekly-${weekKey()}-${campaign.slug}-${campaign.multiplier}`;
          if (sentKeysStore.has(key)) continue;
          newCampaigns.push(campaign);
          await sentKeysStore.add(key);
        }
      } else {
        for (const campaign of campaigns) {
          if (!campaign.slug) continue;
          const normalizedFavSlugs = allFavSlugs.map(s =>
            s.replace(/^tn_/, '').replace(/^sas_/, ''));
          const normalizedCampaignSlug = campaign.slug.replace(/^tn_/, '').replace(/^sas_/, '');
          if (!normalizedFavSlugs.includes(normalizedCampaignSlug)) continue;
          if ((campaign.multiplier ?? 1) <= 1) continue;
          const key = `${deviceId}-${campaign.slug}-${campaign.multiplier}`;
          if (sentKeysStore.has(key)) continue;
          newCampaigns.push(campaign);
          await sentKeysStore.add(key);
        }
      }
      if (!newCampaigns.length) continue;

      const tgLines = newCampaigns
        .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
        .map(c => bvTelegramLine(c))
        .join('\n');

      const headerText = isFreeTier
        ? (newCampaigns.length === 1
            ? `🔔 <b>Ukens beste tilbud: ${newCampaigns[0].title}</b>`
            : `🔔 <b>Ukens ${newCampaigns.length} beste tilbud</b>`)
        : (newCampaigns.length === 1
            ? `🔔 <b>${newCampaigns[0].title}</b> har ${newCampaigns[0].multiplier}x bonus akkurat nå!`
            : `🔔 <b>${newCampaigns.length} favorittbutikker har kampanje!</b>`);

      const msg = `${headerText}\n\n${tgLines}\n\n${BV_TG_REMINDER}`;

      const tgChatId = telegramDeviceStore.get(deviceId) || (favs.telegram ? telegramLinkStore.get(favs.telegram) : null);
      if (!tgChatId && favs.telegram) {
        console.log(`[CHECKFAV] ${deviceId}: @${favs.telegram} har ikke startet @bonusvarsel_varsel_bot ennå - kan ikke sende Telegram`);
      }
      const tgOk = tgChatId ? await sendTelegram(msg, tgChatId) : false;

      if (favs.email) {
        const htmlCards = newCampaigns
          .sort((a,b) => (b.multiplier??0)-(a.multiplier??0))
          .map(c => bvOfferCard(c))
          .join('');
        const emailHeader = isFreeTier
          ? (newCampaigns.length === 1 ? newCampaigns[0].title + ' er ukens beste tilbud!' : 'Ukens ' + newCampaigns.length + ' beste tilbud')
          : (newCampaigns.length === 1 ? newCampaigns[0].title + ' har kampanje!' : newCampaigns.length + ' favorittbutikker har kampanje!');
        const htmlMsg = `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 ${emailHeader}</h2>${htmlCards}${BV_EMAIL_REMINDER}</div>`;
        await sendEmail(
          favs.email,
          isFreeTier ? '🔔 Bonusvarsel – ukens beste tilbud!' : '🔔 Bonusvarsel – kampanje hos favorittene dine!',
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

app.post("/dev/test-weekly-fallback", express.json(), async (req, res) => {
  try {
    const deviceId = req.headers["x-device-id"] || "default";
    const favs = deviceFavorites[deviceId];
    if (!favs) {
      return res.status(404).json({ ok: false, error: "Ingen enhet med denne x-device-id er registrert" });
    }

    const campaigns = await fetchAllCampaigns("elite");
    const topGeneral = campaigns
      .filter((c) => c.slug && (c.multiplier ?? 1) > 1)
      .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
      .slice(0, 2);

    if (!topGeneral.length) {
      return res.json({ ok: true, sent: false, reason: "Ingen kampanjer funnet akkurat nå" });
    }

    const tgLines = topGeneral.map((c) => bvTelegramLine(c)).join("\n");
    const msg = `🔔 <b>[TEST] ${topGeneral.length} tilbud du bør sjekke!</b>\n\n${tgLines}\n\n${BV_TG_REMINDER}\n\n<i>(Dette er en manuell test - den ekte ukentlige meldingen kommer fortsatt onsdag kl 18 som normalt.)</i>`;

    const tgChatId = telegramDeviceStore.get(deviceId) || (favs.telegram ? telegramLinkStore.get(favs.telegram) : null);
    const tgOk = tgChatId ? await sendTelegram(msg, tgChatId) : false;

    let emailOk = false;
    if (favs.email) {
      const htmlCards = topGeneral.map((c) => bvOfferCard(c)).join("");
      const htmlMsg = `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 [TEST] ${topGeneral.length} tilbud du bør sjekke!</h2>${htmlCards}${BV_EMAIL_REMINDER}<p style="color:#94A3B8;font-size:12px;">(Dette er en manuell test - den ekte ukentlige meldingen kommer fortsatt onsdag kl 18 som normalt.)</p></div>`;
      emailOk = await sendEmail(favs.email, "🔔 [TEST] Bonusvarsel – ukens tilbud", htmlMsg);
    }

    res.json({
      ok: true,
      sent: true,
      telegramSent: tgOk,
      emailSent: emailOk,
      campaigns: topGeneral.map((c) => ({ title: c.title, multiplier: c.multiplier, source: c.source })),
    });
  } catch (e) {
    console.error("[dev/test-weekly-fallback] feil:", e);
    res.status(500).json({ ok: false, error: String(e) });
  }
});


app.post("/dev/reset-sent-keys", async (req, res) => {
  state.sentCampaignKeys = new Set();
  await sentKeysStore.reset();
  res.json({ ok: true, message: "sentCampaignKeys nullstilt (minne + Firestore)", store: sentKeysStore.status() });
});

app.post("/dev/monitor-check", async (req, res) => {
  try {
    const result = await runMonitorCheck();
    res.json({ ok: true, result });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

const monitorIntervalMs = Number(process.env.MONITOR_INTERVAL_MS || 30 * 60 * 1000);
initMonitor({ fetchAllCampaigns, sendTelegram });
startMonitor(monitorIntervalMs);

sentKeysStore.init();
sentKeysStore.warmUp().catch((e) => console.error('[sentKeysStore] warmUp error:', e));
telegramLinkStore.init();
telegramLinkStore.warmUp().catch((e) => console.error('[telegramLinkStore] warmUp error:', e));
telegramDeviceStore.init();
telegramDeviceStore.warmUp().catch((e) => console.error('[telegramDeviceStore] warmUp error:', e));

app.listen(port, () => {
  console.log(`API running on http://127.0.0.1:${port}`);
  console.log(`DEV routes enabled: ${enableDevRoutes}`);
});
// deploy-trigger tir. 30 jun. 2026 00.08.24 CEST
