#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_796.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("api/server.js")
text = p.read_text()

pattern = re.compile(
    r'''async function fetchCampaigns\(\)\s*\{[\s\S]*?\n\}''',
    re.MULTILINE
)

replacement = r'''async function fetchCampaigns() {
  const apiUrl =
    "https://onlineshopping.loyaltykey.com/api/v1/campaigns?filter[channel]=SAS&filter[language]=nb&filter[country]=NO&filter[amount]=20";

  try {
    const res = await fetch(apiUrl, {
      headers: {
        "User-Agent": "BonusVarsel/1.0 (Local Debug)",
        "Accept": "application/json, text/plain, */*",
      },
    });

    if (res.ok) {
      const data = await res.json();

      const rawItems = Array.isArray(data)
        ? data
        : Array.isArray(data?.data)
            ? data.data
            : Array.isArray(data?.campaigns)
                ? data.campaigns
                : Array.isArray(data?.items)
                    ? data.items
                    : [];

      const mapped = rawItems
        .map((item, index) => {
          const title =
            item?.title ??
            item?.name ??
            item?.headline ??
            item?.shop_name ??
            item?.shopName ??
            `campaign-${index + 1}`;

          const rawUrl =
            item?.url ??
            item?.link ??
            item?.shop_url ??
            item?.shopUrl ??
            item?.tracking_url ??
            item?.trackingUrl ??
            null;

          const rateCandidates = [
            item?.multiplier,
            item?.rate,
            item?.amount,
            item?.value,
            item?.reward_multiplier,
            item?.rewardMultiplier,
            item?.campaign_multiplier,
            item?.campaignMultiplier,
          ];

          let multiplier = null;
          for (const candidate of rateCandidates) {
            const n = Number(candidate);
            if (Number.isFinite(n) && n > 0) {
              multiplier = n;
              break;
            }
          }

          const textHaystack = [
            title,
            item?.description,
            item?.subtitle,
            item?.body,
            item?.text,
          ]
            .filter(Boolean)
            .join(" ");

          if (multiplier == null) {
            const m = String(textHaystack).match(/(\d+)\s*x/i);
            if (m) multiplier = Number(m[1]);
          }

          return {
            id: item?.id ?? `campaign-${index + 1}`,
            title: String(title),
            multiplier,
            url: rawUrl,
            raw: item,
          };
        })
        .filter((item) => item.title && item.multiplier != null);

      if (mapped.length > 0) {
        return mapped;
      }
    }
  } catch (e) {
    console.error("fetchCampaigns JSON API failed:", String(e));
  }

  const url = "https://onlineshopping.flysas.com/nb-NO/kampanjer/1";

  const r = await fetch(url, {
    headers: {
      "User-Agent": "BonusVarsel/1.0 (Codespaces)"
    }
  });

  if (!r.ok) {
    throw new Error(`Campaign page fetch failed: ${r.status}`);
  }

  const html = await r.text();
  const $ = cheerio.load(html);
  const items = [];

  $("a").each((_, a) => {
    const href = $(a).attr("href") || "";
    const text = $(a).text().replace(/\s+/g, " ").trim();

    if (!text || text.length < 10) return;

    const absolute = href.startsWith("http")
      ? href
      : href.startsWith("/")
        ? `https://onlineshopping.flysas.com${href}`
        : `https://onlineshopping.flysas.com/${href}`;

    const lower = text.toLowerCase();
    const looksLikeCampaign =
      lower.includes("poeng") || lower.includes("bonus") || /(\d+\s*x)/i.test(text);

    if (!looksLikeCampaign) return;

    const m = text.match(/(\d+)\s*x/i);
    const multiplier = m ? Number(m[1]) : null;

    items.push({
      title: text,
      multiplier,
      url: absolute,
    });
  });

  const seen = new Set();
  return items
    .filter((x) => {
      const k = `${x.url}::${x.title}`;
      if (seen.has(k)) return false;
      seen.add(k);
      return true;
    })
    .filter((x) => x.multiplier != null)
    .slice(0, 50);
}'''

new_text, count = pattern.subn(replacement, text, count=1)

if count != 1:
    raise SystemExit("❌ Fant ikke fetchCampaigns()-blokken å erstatte")

p.write_text(new_text)
print("✅ Byttet fetchCampaigns() til LoyaltyKey API først, HTML fallback etterpå")
PY

node --check api/server.js
echo "✅ 796 ferdig"
