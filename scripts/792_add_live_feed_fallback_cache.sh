#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_792.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

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
  sentCampaignKeys: new Set(),
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
  lastGoodCampaigns: [],
  lastGoodCampaignsAt: null,
};"""

if old_state not in text:
    raise SystemExit("❌ Fant ikke state-blokken for fallback-cache")
text = text.replace(old_state, new_state, 1)

old_reset = """function resetState() {
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

new_reset = """function resetState() {
  state.activatedNotifications = [];
  state.seededOffers = [];
  state.sentCampaignKeys = new Set();
  state.lastGoodCampaigns = [];
  state.lastGoodCampaignsAt = null;
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

if old_reset not in text:
    raise SystemExit("❌ Fant ikke resetState()-blokken for fallback-cache")
text = text.replace(old_reset, new_reset, 1)

old_tick = """async function evaluateLivePipelineTick() {
  try {
    const simulationId = `auto-${Date.now()}`;
    const campaigns = await fetchCampaigns();
    const sorted = [...campaigns]
      .sort((a, b) => Number(b.multiplier || 0) - Number(a.multiplier || 0))
      .slice(0, 20);

    const evaluated = sorted.map((item) => {
      const evaluation = evaluateCampaign(item, {
        threshold: 8,
        level: "premium",
        campaign: true,
      });

      return {
        ...item,
        evaluation,
        dedupeKey: campaignKey(item),
      };
    });

    const shouldNotifyItems = evaluated.filter((item) => item.evaluation.shouldNotify);
    const deduped = shouldNotifyItems.filter((item) => !state.sentCampaignKeys.has(item.dedupeKey));

    const scanned = sorted.length;
    const queued = Math.min(deduped.length, 5);
    const dispatchable = deduped.slice(0, queued);
    const dispatchedItems = dispatchable.slice(0, 3);

    state.activatedNotifications = dispatchedItems.map((item, i) => ({
      id: `${simulationId}-notification-${i + 1}`,
      title: item.title,
      rate: item.multiplier ?? 0,
      level: "premium",
      campaign: true,
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
      source: "live-feed-auto",
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
      source: state.pipeline.source,
      pipeline: {
        scanned,
        queued,
        dispatched,
      },
    };
  } catch (e) {
    state.pipeline = {
      ...state.pipeline,
      scanStatus: "failed",
      queueStatus: "idle",
      dispatchStatus: "idle",
      lastUpdated: nowIso(),
      source: "live-feed-auto",
      summary: `auto pipeline failed: ${String(e)}`,
    };
    return {
      ok: false,
      error: String(e),
    };
  }
}"""

new_tick = """async function evaluateLivePipelineTick() {
  const simulationId = `auto-${Date.now()}`;
  let campaigns = [];
  let usedCache = false;
  let fetchError = null;

  try {
    campaigns = await fetchCampaigns();

    if (Array.isArray(campaigns) && campaigns.length > 0) {
      state.lastGoodCampaigns = campaigns;
      state.lastGoodCampaignsAt = nowIso();
    } else if (Array.isArray(state.lastGoodCampaigns) && state.lastGoodCampaigns.length > 0) {
      campaigns = state.lastGoodCampaigns;
      usedCache = true;
    }
  } catch (e) {
    fetchError = String(e);
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
      threshold: 8,
      level: "premium",
      campaign: true,
    });

    return {
      ...item,
      evaluation,
      dedupeKey: campaignKey(item),
    };
  });

  const shouldNotifyItems = evaluated.filter((item) => item.evaluation.shouldNotify);
  const deduped = shouldNotifyItems.filter((item) => !state.sentCampaignKeys.has(item.dedupeKey));

  const scanned = sorted.length;
  const queued = Math.min(deduped.length, 5);
  const dispatchable = deduped.slice(0, queued);
  const dispatchedItems = dispatchable.slice(0, 3);

  state.activatedNotifications = dispatchedItems.map((item, i) => ({
    id: `${simulationId}-notification-${i + 1}`,
    title: item.title,
    rate: item.multiplier ?? 0,
    level: "premium",
    campaign: true,
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
  const source = usedCache ? "live-feed-cache" : "live-feed-auto";

  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • queued=${queued} • dispatched=${dispatched}`;
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
  };
}"""

if old_tick not in text:
    raise SystemExit("❌ Fant ikke evaluateLivePipelineTick()-blokken")
text = text.replace(old_tick, new_tick, 1)

p.write_text(text)
print("✅ La inn fallback-cache for live feed")
PY

node --check api/server.js
echo "✅ 792 ferdig"
