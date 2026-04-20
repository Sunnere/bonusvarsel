#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_801.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("api/server.js")
text = p.read_text()

pattern = re.compile(
    r'async function fetchCampaigns\(\)\s*\{[\s\S]*?\n\}',
    re.MULTILINE
)

replacement = '''async function fetchCampaigns() {
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
}'''

new_text, count = pattern.subn(replacement, text, count=1)

if count != 1:
    raise SystemExit("❌ Fant ikke fetchCampaigns()-blokken å erstatte")

p.write_text(new_text)
print("✅ Hard-erstattet fetchCampaigns() med fungerende LoyaltyKey-versjon")
PY

node --check "$FILE"
echo
grep -n "async function fetchCampaigns" "$FILE"
echo "✅ 801 ferdig"
