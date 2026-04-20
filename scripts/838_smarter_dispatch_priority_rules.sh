#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_838.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("api/server.js")
text = p.read_text()
original = text

# 1) Strammere default env-verdier for smart dispatch
text = text.replace(
    "const autoDispatchMinMultiplier = Number(process.env.AUTO_DISPATCH_MIN_MULTIPLIER || 2);",
    "const autoDispatchMinMultiplier = Number(process.env.AUTO_DISPATCH_MIN_MULTIPLIER || 3);",
)
text = text.replace(
    "const autoDispatchMinScore = Number(process.env.AUTO_DISPATCH_MIN_SCORE || 14);",
    "const autoDispatchMinScore = Number(process.env.AUTO_DISPATCH_MIN_SCORE || 18);",
)

# 2) Smartere sortering: fixed først, så notify, så multiplier, så score
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
    const fixedA =
      String(a.raw?.commission_type || '').toLowerCase() === 'fixed' ? 1 : 0;
    const fixedB =
      String(b.raw?.commission_type || '').toLowerCase() === 'fixed' ? 1 : 0;
    if (fixedB !== fixedA) return fixedB - fixedA;

    const finalNotifyA = a.evaluation.shouldNotify == true ? 1 : 0;
    const finalNotifyB = b.evaluation.shouldNotify == true ? 1 : 0;
    if (finalNotifyB !== finalNotifyA) return finalNotifyB - finalNotifyA;

    const finalMultiplierA = Number(a.multiplier || 0);
    const finalMultiplierB = Number(b.multiplier || 0);
    if (finalMultiplierB !== finalMultiplierA) {
      return finalMultiplierB - finalMultiplierA;
    }

    const finalScoreA = Number(a.evaluation.score || 0);
    const finalScoreB = Number(b.evaluation.score || 0);
    if (finalScoreB !== finalScoreA) return finalScoreB - finalScoreA;

    return String(a.title || '').localeCompare(String(b.title || ''));
  });
"""

if old_sort not in text:
    raise SystemExit("❌ Fant ikke prioritized-sort-blokken")
text = text.replace(old_sort, new_sort, 1)

# 3) Smartere dispatch-kandidater
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
"""

new_dispatch = """  const dispatchCandidates = shouldNotifyItems.filter((item) => {
    const multiplier = Number(item.multiplier || 0);
    const score = Number(item.evaluation?.score || 0);
    const commissionType = String(item.raw?.commission_type || '').toLowerCase();

    if (commissionType === 'fixed') return true;
    if (multiplier >= autoDispatchMinMultiplier) return true;
    if (score >= autoDispatchMinScore) return true;

    return false;
  });
"""

if old_dispatch not in text:
    raise SystemExit("❌ Fant ikke dispatchCandidates-blokken")
text = text.replace(old_dispatch, new_dispatch, 1)

# 4) Gjør recentCampaigns mer forklarende for UI/debug
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

new_recent = """    recentCampaigns: prioritized.slice(0, 5).map((item) => {
      const commissionType = String(item.raw?.commission_type || '').toLowerCase();
      const multiplier = Number(item.multiplier || 0);
      const score = Number(item.evaluation?.score || 0);
      const dispatchEligible =
        commissionType === 'fixed' ||
        multiplier >= autoDispatchMinMultiplier ||
        score >= autoDispatchMinScore;

      const priorityReason =
        commissionType === 'fixed'
          ? 'fixed commission'
          : multiplier >= autoDispatchMinMultiplier
              ? `multiplier ${multiplier} >= ${autoDispatchMinMultiplier}`
              : score >= autoDispatchMinScore
                  ? `score ${score} >= ${autoDispatchMinScore}`
                  : 'not selected';

      return {
        title: item.title,
        multiplier: item.multiplier,
        url: item.url,
        shouldNotify: item.evaluation.shouldNotify,
        dispatchEligible,
        reason: item.evaluation.reason,
        score: item.evaluation.score,
        commissionType: item.raw?.commission_type ?? null,
        priorityReason,
      };
    }),
"""

if old_recent not in text:
    raise SystemExit("❌ Fant ikke recentCampaigns-blokken")
text = text.replace(old_recent, new_recent, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Gjorde dispatch-prioritering smartere")
PY

echo
node --check "$FILE"
echo "✅ node --check OK"

echo
flutter analyze
echo "✅ 838 ferdig"
