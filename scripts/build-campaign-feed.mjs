import fs from "node:fs";

const campaigns = JSON.parse(fs.readFileSync("data/campaigns.normalized.json", "utf8"));
const shops = JSON.parse(fs.readFileSync("data/shops.normalized.json", "utf8"));

const shopByUuid = new Map(shops.map(s => [s.uuid, s]));

function parseNorDate(ddmmyyyy) {
  // "18.01.2026" -> "2026-01-18"
  if (!ddmmyyyy || typeof ddmmyyyy !== "string") return null;
  const m = ddmmyyyy.match(/^(\d{2})\.(\d{2})\.(\d{4})$/);
  if (!m) return null;
  const [, dd, mm, yyyy] = m;
  return `${yyyy}-${mm}-${dd}`;
}

const feed = campaigns.map(c => {
  const shop = shopByUuid.get(c.uuid) || {};
  const endsAt = parseNorDate(c.campaign_ends_date);

  return {
    uuid: c.uuid,
    shop_name: c.name ?? shop.name ?? null,
    slug: c.slug ?? shop.slug ?? null,
    categoryId: c.categoryId ?? shop.categoryId ?? null,
    commission_type: c.commission_type ?? shop.commission_type ?? null,
    points_base: c.points ?? shop.points ?? null,
    points_campaign: c.points_campaign ?? null,
    ends_at: endsAt, // YYYY-MM-DD
    image_url: c.image_url ?? shop.image_url ?? null,
    banner_url: c.image_banner_url ?? shop.image_banner_url ?? null,
    logo: shop.logo ?? null,
    points_channel: shop.points_channel ?? null,
  };
}).sort((a, b) => (b.points_campaign ?? 0) - (a.points_campaign ?? 0));

fs.writeFileSync("data/campaigns.feed.json", JSON.stringify(feed, null, 2));
console.log(`Wrote data/campaigns.feed.json (${feed.length} items)`);
