#!/usr/bin/env bash
set -euo pipefail

API_FILE="api/server.js"
PANEL_FILE="lib/widgets/dev_pipeline_panel.dart"

[[ -f "$API_FILE" ]] || { echo "❌ Fant ikke $API_FILE"; exit 1; }
[[ -f "$PANEL_FILE" ]] || { echo "❌ Fant ikke $PANEL_FILE"; exit 1; }

cp "$API_FILE" "$API_FILE.bak_785.$(date +%s)"
cp "$PANEL_FILE" "$PANEL_FILE.bak_785.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

# 1) legg inn interval-konfig hvis den mangler
if "AUTO_PIPELINE_INTERVAL_MS" not in text:
    marker = 'const appVersion = process.env.APP_VERSION || "dev-local";\n'
    insert = marker + 'const autoPipelineIntervalMs = Number(process.env.AUTO_PIPELINE_INTERVAL_MS || 60000);\n'
    if marker not in text:
        raise SystemExit("❌ Fant ikke appVersion-markør i api/server.js")
    text = text.replace(marker, insert, 1)

# 2) legg inn automatisk pipeline-tick hvis den mangler
if "async function evaluateLivePipelineTick()" not in text:
    marker = "app.listen(port, () => {"
    helper = r'''
async function evaluateLivePipelineTick() {
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

'''
    if marker not in text:
        raise SystemExit("❌ Fant ikke app.listen i api/server.js")
    text = text.replace(marker, helper + "\n" + marker, 1)

# 3) start auto pipeline hvis ikke allerede startet
start_snippet = """
if (enableDevRoutes) {
  startAutoPipeline();
}

app.listen(port, () => {"""
if "startAutoPipeline();" not in text:
    marker = "app.listen(port, () => {"
    if marker not in text:
        raise SystemExit("❌ Fant ikke app.listen for startAutoPipeline")
    text = text.replace(marker, start_snippet, 1)

p.write_text(text)
print("✅ La inn automatisk live pipeline i backend")
PY

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()

# 1) import Timer
if "import 'dart:async';" not in text:
    marker = "import 'package:flutter/material.dart';\n"
    if marker not in text:
        raise SystemExit("❌ Fant ikke material-import i dev_pipeline_panel.dart")
    text = text.replace(marker, "import 'dart:async';\n" + marker, 1)

# 2) state field for timer
if "Timer? _autoRefreshTimer;" not in text:
    anchor = "  List<Map<String, dynamic>> _recentCampaigns = [];\n"
    if anchor not in text:
        raise SystemExit("❌ Fant ikke anker for _autoRefreshTimer")
    text = text.replace(anchor, anchor + "  Timer? _autoRefreshTimer;\n", 1)

# 3) initState auto refresh
old_init = """  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }
"""
new_init = """  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshStatus(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
"""
if old_init in text and "Timer.periodic(" not in text:
    text = text.replace(old_init, new_init, 1)

p.write_text(text)
print("✅ La inn automatisk refresh i DevPipelinePanel")
PY

node --check api/server.js
flutter analyze
echo "✅ 785 ferdig"
