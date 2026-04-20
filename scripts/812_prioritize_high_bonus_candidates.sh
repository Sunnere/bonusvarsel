#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_812.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

old = """  const shouldNotifyItems = evaluated.filter((item) => item.evaluation.shouldNotify);
  const deduped = shouldNotifyItems.filter((item) => !state.sentCampaignKeys.has(item.dedupeKey));

  const scanned = sorted.length;
  const queued = Math.min(deduped.length, 5);
  const dispatchable = deduped.slice(0, queued);
  const dispatchedItems = dispatchable.slice(0, 3);
"""

new = """  const prioritized = [...evaluated].sort((a, b) => {
    finalNotifyA = a.evaluation.shouldNotify == true ? 1 : 0;
    finalNotifyB = b.evaluation.shouldNotify == true ? 1 : 0;
    if (finalNotifyB != finalNotifyA) return finalNotifyB - finalNotifyA;

    finalMultiplierA = Number(a.multiplier || 0);
    finalMultiplierB = Number(b.multiplier || 0);
    if (finalMultiplierB != finalMultiplierA) return finalMultiplierB - finalMultiplierA;

    finalScoreA = Number(a.evaluation.score || 0);
    finalScoreB = Number(b.evaluation.score || 0);
    if (finalScoreB != finalScoreA) return finalScoreB - finalScoreA;

    return String(a.title || '').localeCompare(String(b.title || ''));
  });

  const shouldNotifyItems = prioritized.filter((item) => item.evaluation.shouldNotify);
  const deduped = shouldNotifyItems.filter((item) => !state.sentCampaignKeys.has(item.dedupeKey));

  const scanned = sorted.length;
  const queued = Math.min(deduped.length, 5);
  const dispatchable = deduped.slice(0, queued);
  const dispatchedItems = dispatchable.slice(0, 3);
"""

if old not in text:
    raise SystemExit("❌ Fant ikke prioriteringsblokken i evaluateLivePipelineTick()")

text = text.replace(old, new, 1)

old_recent = """    recentCampaigns: evaluated.slice(0, 5).map((item) => ({
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
      reason: item.evaluation.reason,
      score: item.evaluation.score,
    })),
"""

if old_recent not in text:
    raise SystemExit("❌ Fant ikke recentCampaigns-blokken")

text = text.replace(old_recent, new_recent, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn prioritering av høy bonus og høy score")
PY

node --check "$FILE"
flutter analyze
echo "✅ 812 ferdig"
