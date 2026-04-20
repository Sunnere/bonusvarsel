#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_798.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

old = """      const mapped = rawItems
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
        .filter((item) => item.title && item.multiplier != null);"""

new = """      const mapped = rawItems
        .map((item, index) => {
          const title =
            item?.name ??
            item?.title ??
            item?.headline ??
            item?.shop_name ??
            item?.shopName ??
            `campaign-${index + 1}`;

          const slug = item?.slug ?? null;

          const rawUrl =
            item?.url ??
            item?.link ??
            item?.shop_url ??
            item?.shopUrl ??
            item?.tracking_url ??
            item?.trackingUrl ??
            (slug ? `https://onlineshopping.flysas.com/nb-NO/butikk/${slug}` : null);

          const basePoints = Number(item?.points ?? 0);
          const campaignPoints = Number(item?.points_campaign ?? 0);

          let multiplier = null;

          if (Number.isFinite(basePoints) &&
              Number.isFinite(campaignPoints) &&
              basePoints > 0 &&
              campaignPoints > 0) {
            multiplier = Number((campaignPoints / basePoints).toFixed(2));
          }

          if (!Number.isFinite(multiplier) || multiplier <= 0) {
            const rateCandidates = [
              item?.multiplier,
              item?.rate,
              item?.amount,
              item?.value,
              item?.reward_multiplier,
              item?.rewardMultiplier,
              item?.campaign_multiplier,
              item?.campaignMultiplier,
              item?.points_campaign,
            ];

            for (const candidate of rateCandidates) {
              const n = Number(candidate);
              if (Number.isFinite(n) && n > 0) {
                multiplier = n;
                break;
              }
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
            const m = String(textHaystack).match(/(\d+(?:[\\.,]\\d+)?)\\s*x/i);
            if (m) multiplier = Number(String(m[1]).replace(",", "."));
          }

          return {
            id: item?.uuid ?? item?.id ?? `campaign-${index + 1}`,
            title: String(title),
            multiplier,
            url: rawUrl,
            slug,
            raw: item,
          };
        })
        .filter((item) => item.title && item.multiplier != null);"""

if old not in text:
    raise SystemExit("❌ Fant ikke forventet LoyaltyKey mapping-blokk i api/server.js")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Fikset LoyaltyKey campaign-mapping")
PY

node --check api/server.js
echo "✅ 798 ferdig"
