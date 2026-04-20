#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_849.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

old_sort = """  const prioritized = [...evaluated].sort((a, b) => {
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

new_sort = """  const prioritized = [...evaluated].sort((a, b) => {
    const finalNotifyA = a.evaluation.shouldNotify == true ? 1 : 0;
    const finalNotifyB = b.evaluation.shouldNotify == true ? 1 : 0;
    if (finalNotifyB !== finalNotifyA) return finalNotifyB - finalNotifyA;

    const fixedA =
      String(a.raw?.commission_type || '').toLowerCase() === 'fixed' ? 100 : 0;
    const fixedB =
      String(b.raw?.commission_type || '').toLowerCase() === 'fixed' ? 100 : 0;

    const finalMultiplierA = Number(a.multiplier || 0);
    const finalMultiplierB = Number(b.multiplier || 0);

    const finalScoreA = Number(a.evaluation.score || 0);
    const finalScoreB = Number(b.evaluation.score || 0);

    const businessScoreA = fixedA + (finalMultiplierA * 10) + finalScoreA;
    const businessScoreB = fixedB + (finalMultiplierB * 10) + finalScoreB;

    if (businessScoreB !== businessScoreA) {
      return businessScoreB - businessScoreA;
    }

    if (finalMultiplierB !== finalMultiplierA) {
      return finalMultiplierB - finalMultiplierA;
    }

    if (finalScoreB !== finalScoreA) return finalScoreB - finalScoreA;

    return String(a.title || '').localeCompare(String(b.title || ''));
  });
"""

if old_sort not in text:
    raise SystemExit("❌ Fant ikke prioritized-sort-blokken")

text = text.replace(old_sort, new_sort, 1)

old_recent = """      return {
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
"""

new_recent = """      const businessScore =
        (commissionType === 'fixed' ? 100 : 0) +
        (multiplier * 10) +
        score;

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
        businessScore,
      };
"""

if old_recent not in text:
    raise SystemExit("❌ Fant ikke recentCampaigns return-blokken")

text = text.replace(old_recent, new_recent, 1)

old_notif = """  state.activatedNotifications = dispatchedItems.map((item, i) => ({
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

new_notif = """  state.activatedNotifications = dispatchedItems.map((item, i) => {
    const commissionType = String(item.raw?.commission_type || '').toLowerCase();
    const multiplier = Number(item.multiplier || 0);
    const score = Number(item.evaluation.score || 0);
    const businessScore =
      (commissionType === 'fixed' ? 100 : 0) +
      (multiplier * 10) +
      score;

    return {
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
      businessScore,
    };
  });
"""

if old_notif not in text:
    raise SystemExit("❌ Fant ikke activatedNotifications-blokken")

text = text.replace(old_notif, new_notif, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn smart revenue scoring i backend")
PY

echo
node --check "$FILE"
echo "✅ node --check OK"

echo
flutter analyze
echo "✅ 849 ferdig"
