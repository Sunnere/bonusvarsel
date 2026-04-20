#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_837.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

# 1) Stram default config hvis den finnes
text = text.replace(
    "const autoDispatchMinMultiplier = Number(process.env.AUTO_DISPATCH_MIN_MULTIPLIER || 2);",
    "const autoDispatchMinMultiplier = Number(process.env.AUTO_DISPATCH_MIN_MULTIPLIER || 3);",
)
text = text.replace(
    "const autoDispatchMinScore = Number(process.env.AUTO_DISPATCH_MIN_SCORE || 14);",
    "const autoDispatchMinScore = Number(process.env.AUTO_DISPATCH_MIN_SCORE || 18);",
)
text = text.replace(
    "const autoDispatchMaxPerTick = Number(process.env.AUTO_DISPATCH_MAX_PER_TICK || 3);",
    "const autoDispatchMaxPerTick = Number(process.env.AUTO_DISPATCH_MAX_PER_TICK || 2);",
)

# 2) Smart prioritering: fixed først, så multiplier, så score
old_sort = """  const prioritized = [...evaluated].sort((a, b) => {
    const finalNotifyA = a.evaluation.shouldNotify == true ? 1 : 0;
    const finalNotifyB = b.evaluation.shouldNotify == true ? 1 : 0;
    if (finalNotifyB != finalNotifyA) return finalNotifyB - finalNotifyA;

    const finalMultiplierA = Number(a.multiplier || 0);
    const finalMultiplierB = Number(b.multiplier || 0);
    if (finalMultiplierB != finalMultiplierA) return finalMultiplierB - finalMultiplierA;

    const finalScoreA = Number(a.evaluation.score || 0);
    const finalScoreB = Number(b.evaluation.score || 0);
    if (finalScoreB != finalScoreA) return finalScoreB - finalScoreA;

    return String(a.title || '').localeCompare(String(b.title || ''));
  });
"""

new_sort = """  const prioritized = [...evaluated].sort((a, b) => {
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
"""

if old_sort not in text:
    raise SystemExit("❌ Fant ikke prioritized-sort-blokken")
text = text.replace(old_sort, new_sort, 1)

# 3) Smart dispatch-candidates + enkel merchant-dedupe per tick
old_dispatch = """  const dispatchCandidates = shouldNotifyItems.filter((item) => {
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

new_dispatch = """  const dispatchCandidates = shouldNotifyItems.filter((item) => {
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
"""

if old_dispatch not in text:
    raise SystemExit("❌ Fant ikke dispatchCandidates-blokken")
text = text.replace(old_dispatch, new_dispatch, 1)

# 4) Gjør summary tydeligere
old_summary = """  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • dispatchCandidates=${dispatchCandidates.length} • queued=${queued} • dispatched=${dispatched}`;
"""
new_summary = """  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • dispatchCandidates=${dispatchCandidates.length} • uniqueDispatchCandidates=${uniqueDispatchCandidates.length} • queued=${queued} • dispatched=${dispatched}`;
"""
if old_summary in text:
    text = text.replace(old_summary, new_summary, 1)

# 5) Gjør recentCampaigns mer forklarende for UI/debug
old_recent = """    recentCampaigns: prioritized.slice(0, 5).map((item) => ({
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

new_recent = """    recentCampaigns: prioritized.slice(0, 5).map((item) => ({
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
"""

if old_recent in text:
    text = text.replace(old_recent, new_recent, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort i api/server.js")

p.write_text(text)
print("✅ Gjorde dispatch smart: fixed først, strengere kandidatfilter, maks 2 per tick")
PY

echo
node --check "$FILE"
echo "✅ node --check OK"
