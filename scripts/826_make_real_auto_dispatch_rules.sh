#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_826.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

# 1) legg inn dispatch-config hvis den mangler
marker = 'let currentAutoPipelineThreshold = Number(process.env.AUTO_PIPELINE_THRESHOLD || 2);\n'
insert = marker + """const autoDispatchMinMultiplier = Number(process.env.AUTO_DISPATCH_MIN_MULTIPLIER || 2);
const autoDispatchMinScore = Number(process.env.AUTO_DISPATCH_MIN_SCORE || 14);
const autoDispatchMaxPerTick = Number(process.env.AUTO_DISPATCH_MAX_PER_TICK || 3);
"""
if "autoDispatchMinMultiplier" not in text:
    if marker not in text:
        raise SystemExit("❌ Fant ikke threshold-marker i api/server.js")
    text = text.replace(marker, insert, 1)

# 2) bytt ut dispatch-logikken i evaluateLivePipelineTick
old_block = """  const shouldNotifyItems = prioritized.filter((item) => item.evaluation.shouldNotify);
  const deduped = shouldNotifyItems.filter((item) => !state.sentCampaignKeys.has(item.dedupeKey));

  const scanned = sorted.length;
  const queued = Math.min(deduped.length, 5);
  const dispatchable = deduped.slice(0, queued);
  const dispatchedItems = dispatchable.slice(0, 3);
"""

new_block = """  const shouldNotifyItems = prioritized.filter((item) => item.evaluation.shouldNotify);

  const dispatchCandidates = shouldNotifyItems.filter((item) => {
    const multiplier = Number(item.multiplier || 0);
    const score = Number(item.evaluation?.score || 0);
    const commissionType = String(item.raw?.commission_type || '').toLowerCase();

    return (
      multiplier >= autoDispatchMinMultiplier ||
      score >= autoDispatchMinScore ||
      commissionType == 'fixed'
    );
  });

  const deduped = dispatchCandidates.filter(
    (item) => !state.sentCampaignKeys.has(item.dedupeKey),
  );

  const scanned = sorted.length;
  const queued = Math.min(deduped.length, autoDispatchMaxPerTick);
  const dispatchable = deduped.slice(0, queued);
  const dispatchedItems = dispatchable.slice(0, autoDispatchMaxPerTick);
"""

if old_block not in text:
    raise SystemExit("❌ Fant ikke gammel dispatch-blokk i evaluateLivePipelineTick()")
text = text.replace(old_block, new_block, 1)

# 3) utvid notification-payload med mer ekte metadata
old_notif = """  state.activatedNotifications = dispatchedItems.map((item, i) => ({
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
"""

new_notif = """  state.activatedNotifications = dispatchedItems.map((item, i) => ({
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
"""

if old_notif in text:
    text = text.replace(old_notif, new_notif, 1)

# 4) gjør summary mer ærlig og nyttig
old_summary = """  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • queued=${queued} • dispatched=${dispatched}`;
"""
new_summary = """  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • dispatchCandidates=${dispatchCandidates.length} • queued=${queued} • dispatched=${dispatched}`;
"""
if old_summary in text:
    text = text.replace(old_summary, new_summary, 1)

# 5) legg inn dispatch-flag på recentCampaigns for UI/debug
old_recent = """    recentCampaigns: prioritized.slice(0, 5).map((item) => ({
      title: item.title,
      multiplier: item.multiplier,
      url: item.url,
      shouldNotify: item.evaluation.shouldNotify,
      reason: item.evaluation.reason,
      score: item.evaluation.score,
    })),
"""

new_recent = """    recentCampaigns: prioritized.slice(0, 5).map((item) => ({
      title: item.title,
      multiplier: item.multiplier,
      url: item.url,
      shouldNotify: item.evaluation.shouldNotify,
      dispatchEligible:
        Number(item.multiplier || 0) >= autoDispatchMinMultiplier ||
        Number(item.evaluation?.score || 0) >= autoDispatchMinScore ||
        String(item.raw?.commission_type || '').toLowerCase() == 'fixed',
      reason: item.evaluation.reason,
      score: item.evaluation.score,
      commissionType: item.raw?.commission_type ?? null,
    })),
"""

if old_recent in text:
    text = text.replace(old_recent, new_recent, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort i api/server.js")

p.write_text(text)
print("✅ La inn ekte auto-dispatch-regler")
PY

echo
node --check "$FILE"
echo "✅ node --check OK"

echo
flutter analyze
echo "✅ 826 ferdig"
