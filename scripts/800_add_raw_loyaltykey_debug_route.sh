#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_800.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

route = r'''
app.get("/v1/dev/debug-loyaltykey-raw", async (_, res) => {
  const apiUrl =
    "https://onlineshopping.loyaltykey.com/api/v1/campaigns?filter[channel]=SAS&filter[language]=nb&filter[country]=NO&filter[amount]=20";

  try {
    const response = await fetch(apiUrl, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Accept": "application/json, text/plain, */*",
      },
    });

    const rawText = await response.text();

    let parsed = null;
    let parseError = null;
    try {
      parsed = JSON.parse(rawText);
    } catch (e) {
      parseError = String(e);
    }

    const rawItems = Array.isArray(parsed)
      ? parsed
      : Array.isArray(parsed?.data)
          ? parsed.data
          : Array.isArray(parsed?.campaigns)
              ? parsed.campaigns
              : Array.isArray(parsed?.items)
                  ? parsed.items
                  : [];

    const first = rawItems[0] ?? null;

    let mappedFirst = null;
    if (first) {
      const title =
        first?.name ??
        first?.title ??
        first?.headline ??
        first?.shop_name ??
        first?.shopName ??
        "campaign-1";

      const slug = first?.slug ?? null;

      const rawUrl =
        first?.url ??
        first?.link ??
        first?.shop_url ??
        first?.shopUrl ??
        first?.tracking_url ??
        first?.trackingUrl ??
        (slug ? `https://onlineshopping.flysas.com/nb-NO/butikk/${slug}` : null);

      const basePoints = Number(first?.points ?? 0);
      const campaignPoints = Number(first?.points_campaign ?? 0);

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

      mappedFirst = {
        title,
        slug,
        rawUrl,
        basePoints,
        campaignPoints,
        multiplier,
      };
    }

    res.json({
      ok: true,
      status: response.status,
      contentType: response.headers.get("content-type"),
      parseError,
      topLevelType: Array.isArray(parsed) ? "array" : typeof parsed,
      topLevelKeys:
        parsed && !Array.isArray(parsed) && typeof parsed === "object"
          ? Object.keys(parsed)
          : [],
      rawItemsCount: Array.isArray(rawItems) ? rawItems.length : 0,
      firstRawItem: first,
      firstMappedItem: mappedFirst,
      rawPreview: rawText.slice(0, 800),
    });
  } catch (e) {
    res.status(500).json({
      ok: false,
      error: String(e),
    });
  }
});

'''

if 'app.get("/v1/dev/debug-loyaltykey-raw"' in text:
    print("ℹ️ Route finnes allerede")
else:
    marker = 'app.listen(port, () => {'
    if marker not in text:
      raise SystemExit("❌ Fant ikke app.listen-markør")
    text = text.replace(marker, route + "\n" + marker, 1)
    p.write_text(text)
    print("✅ La inn /v1/dev/debug-loyaltykey-raw")
PY

node --check "$FILE"
echo "✅ 800 ferdig"
