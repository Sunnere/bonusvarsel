#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_775.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

# 1) legg inn dedupe-sett i state
old_state = """  pipeline: {
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
};"""

new_state = """  pipeline: {
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
};"""

if old_state in text:
    text = text.replace(old_state, new_state, 1)
else:
    raise SystemExit("❌ Fant ikke state-blokken i api/server.js")

# 2) reset state må også nullstille dedupe
old_reset = """function resetState() {
  state.activatedNotifications = [];
  state.seededOffers = [];
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
}"""

new_reset = """function resetState() {
  state.activatedNotifications = [];
  state.seededOffers = [];
  state.sentCampaignKeys = new Set();
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
}"""

if old_reset in text:
    text = text.replace(old_reset, new_reset, 1)
else:
    raise SystemExit("❌ Fant ikke resetState() i api/server.js")

# 3) legg inn helper-funksjoner før runSimulation
marker = "async function runSimulation(reqBody = {}) {"
helpers = """
function campaignKey(item) {
  return `${item.url || "no-url"}::${item.title || "untitled"}`;
}

function evaluateCampaign(item, reqBody = {}) {
  const baseRate = Number(item.multiplier || reqBody.rate || 0);
  const threshold = Number(reqBody.threshold || 8);

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

"""
if marker in text and "function evaluateCampaign(item, reqBody = {})" not in text:
    text = text.replace(marker, helpers + marker, 1)

# 4) bytt ut runSimulation med mer ekte logikk
old_run = """async function runSimulation(reqBody = {}) {
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

  const scanned = combined.length;
  const queued = Math.min(scanned, 5);
  const dispatched = Math.min(queued, 3);

  state.activatedNotifications = combined.slice(0, dispatched).map((item, i) => ({
    id: `${simulationId}-notification-${i + 1}`,
    title: item.title,
    rate: item.multiplier ?? reqBody.rate ?? 18,
    level: reqBody.level ?? "premium",
    campaign: reqBody.campaign ?? true,
    activatedAt: nowIso(),
  }));

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
    summary: `scanned=${scanned} • queued=${queued} • dispatched=${dispatched}`,
    recentCampaigns: combined.slice(0, 5).map((item) => ({
      title: item.title,
      multiplier: item.multiplier,
      url: item.url,
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
}"""

new_run = """async function runSimulation(reqBody = {}) {
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
}"""

if old_run in text:
    text = text.replace(old_run, new_run, 1)
else:
    raise SystemExit("❌ Fant ikke runSimulation()-blokken i api/server.js")

p.write_text(text)
print("✅ La inn dedupe, threshold og ekte notify-beslutning i backend")
PY

node --check api/server.js
echo "✅ 775 ferdig"
