#!/usr/bin/env bash
set -euo pipefail

API_FILE="api/server.js"
PANEL_FILE="lib/widgets/dev_pipeline_panel.dart"

[[ -f "$API_FILE" ]] || { echo "❌ Fant ikke $API_FILE"; exit 1; }
[[ -f "$PANEL_FILE" ]] || { echo "❌ Fant ikke $PANEL_FILE"; exit 1; }

cp "$API_FILE" "$API_FILE.bak_793.$(date +%s)"
cp "$PANEL_FILE" "$PANEL_FILE.bak_793.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

old_state = """  sentCampaignKeys: new Set(),
  lastGoodCampaigns: [],
  lastGoodCampaignsAt: null,
};"""

new_state = """  sentCampaignKeys: new Set(),
  lastGoodCampaigns: [],
  lastGoodCampaignsAt: null,
  lastFetchMode: "none",
  lastLiveSuccessAt: null,
  lastUpstreamError: null,
  tickCount: 0,
};"""

if old_state not in text:
    raise SystemExit("❌ Fant ikke state-halen i api/server.js")
text = text.replace(old_state, new_state, 1)

old_reset = """  state.sentCampaignKeys = new Set();
  state.lastGoodCampaigns = [];
  state.lastGoodCampaignsAt = null;
  state.pipeline = {"""

new_reset = """  state.sentCampaignKeys = new Set();
  state.lastGoodCampaigns = [];
  state.lastGoodCampaignsAt = null;
  state.lastFetchMode = "none";
  state.lastLiveSuccessAt = null;
  state.lastUpstreamError = null;
  state.tickCount = 0;
  state.pipeline = {"""

if old_reset not in text:
    raise SystemExit("❌ Fant ikke resetState-felt i api/server.js")
text = text.replace(old_reset, new_reset, 1)

old_tick_head = """async function evaluateLivePipelineTick() {
  const simulationId = `auto-${Date.now()}`;
  let campaigns = [];
  let usedCache = false;
  let fetchError = null;"""

new_tick_head = """async function evaluateLivePipelineTick() {
  state.tickCount += 1;

  const simulationId = `auto-${Date.now()}`;
  let campaigns = [];
  let usedCache = false;
  let fetchError = null;"""

if old_tick_head not in text:
    raise SystemExit("❌ Fant ikke evaluateLivePipelineTick-head")
text = text.replace(old_tick_head, new_tick_head, 1)

old_live_save = """    if (Array.isArray(campaigns) && campaigns.length > 0) {
      state.lastGoodCampaigns = campaigns;
      state.lastGoodCampaignsAt = nowIso();
    } else if (Array.isArray(state.lastGoodCampaigns) && state.lastGoodCampaigns.length > 0) {"""

new_live_save = """    if (Array.isArray(campaigns) && campaigns.length > 0) {
      state.lastGoodCampaigns = campaigns;
      state.lastGoodCampaignsAt = nowIso();
      state.lastLiveSuccessAt = state.lastGoodCampaignsAt;
      state.lastUpstreamError = null;
    } else if (Array.isArray(state.lastGoodCampaigns) && state.lastGoodCampaigns.length > 0) {"""

if old_live_save not in text:
    raise SystemExit("❌ Fant ikke live-save-blokken")
text = text.replace(old_live_save, new_live_save, 1)

old_catch = """  } catch (e) {
    fetchError = String(e);
    if (Array.isArray(state.lastGoodCampaigns) && state.lastGoodCampaigns.length > 0) {
      campaigns = state.lastGoodCampaigns;
      usedCache = true;
    } else {
      campaigns = [];
    }
  }"""

new_catch = """  } catch (e) {
    fetchError = String(e);
    state.lastUpstreamError = fetchError;
    if (Array.isArray(state.lastGoodCampaigns) && state.lastGoodCampaigns.length > 0) {
      campaigns = state.lastGoodCampaigns;
      usedCache = true;
    } else {
      campaigns = [];
    }
  }"""

if old_catch not in text:
    raise SystemExit("❌ Fant ikke catch-blokken i evaluateLivePipelineTick")
text = text.replace(old_catch, new_catch, 1)

old_source = """  const dispatched = dispatchedItems.length;
  const source = usedCache ? "live-feed-cache" : "live-feed-auto";

  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • queued=${queued} • dispatched=${dispatched}`;"""

new_source = """  const dispatched = dispatchedItems.length;
  const source = usedCache ? "live-feed-cache" : "live-feed-auto";
  state.lastFetchMode = source;
  if (!usedCache) {
    state.lastUpstreamError = null;
  }

  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • queued=${queued} • dispatched=${dispatched}`;"""

if old_source not in text:
    raise SystemExit("❌ Fant ikke source/summary-blokken")
text = text.replace(old_source, new_source, 1)

old_pipeline = """    source,
    summary,
    recentCampaigns: evaluated.slice(0, 5).map((item) => ({"""

new_pipeline = """    source,
    summary,
    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
    recentCampaigns: evaluated.slice(0, 5).map((item) => ({"""

if old_pipeline not in text:
    raise SystemExit("❌ Fant ikke pipeline-blokken for statusfelt")
text = text.replace(old_pipeline, new_pipeline, 1)

old_return = """    usedCache,
    fetchError,
    lastGoodCampaignsAt: state.lastGoodCampaignsAt,
  };"""

new_return = """    usedCache,
    fetchError,
    lastGoodCampaignsAt: state.lastGoodCampaignsAt,
    lastFetchMode: state.lastFetchMode,
    lastLiveSuccessAt: state.lastLiveSuccessAt,
    lastUpstreamError: state.lastUpstreamError,
    tickCount: state.tickCount,
  };"""

if old_return not in text:
    raise SystemExit("❌ Fant ikke return-blokken i evaluateLivePipelineTick")
text = text.replace(old_return, new_return, 1)

p.write_text(text)
print("✅ Backend viser live/cache-status tydelig")
PY

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()

old = """                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pipeline meta',
                                  style: TextStyle(
                                    color: _text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Last updated: $lastUpdated',
                                  style: const TextStyle(
                                    color: _textSoft,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Summary: $summary',
                                  style: const TextStyle(
                                    color: _textSoft,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),"""

new = """                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: Builder(
                              builder: (_) {
                                final fetchMode =
                                    (pipeline['lastFetchMode'] ?? '-').toString();
                                final lastLiveSuccessAt =
                                    (pipeline['lastLiveSuccessAt'] ?? '-')
                                        .toString();
                                final lastUpstreamError =
                                    (pipeline['lastUpstreamError'] ?? '-')
                                        .toString();
                                final tickCount =
                                    (pipeline['tickCount'] ?? '-').toString();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pipeline meta',
                                      style: TextStyle(
                                        color: _text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Last updated: $lastUpdated',
                                      style: const TextStyle(
                                        color: _textSoft,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Summary: $summary',
                                      style: const TextStyle(
                                        color: _textSoft,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Feed status',
                                      style: TextStyle(
                                        color: _text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _infoChip('Mode', fetchMode),
                                        _infoChip('Tick count', tickCount),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Last live success: $lastLiveSuccessAt',
                                      style: const TextStyle(
                                        color: _textSoft,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last upstream error: $lastUpstreamError',
                                      style: const TextStyle(
                                        color: _textSoft,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),"""

if old not in text:
    raise SystemExit("❌ Fant ikke Pipeline meta-boksen i dev_pipeline_panel.dart")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ UI viser live/cache-status tydelig")
PY

node --check api/server.js
flutter analyze
echo "✅ 793 ferdig"
