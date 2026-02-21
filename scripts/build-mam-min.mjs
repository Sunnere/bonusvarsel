import fs from "node:fs";

const SRC = "assets/mam.offers.json";
const OUT = "assets/mam.offers.min.json";

const raw = fs.readFileSync(SRC, "utf8");
const j = JSON.parse(raw);

if (!Array.isArray(j.offers)) {
  throw new Error("Expected { offers: [] }");
}

const min = j.offers.map(o => ({
  id: o.id ?? null,
  date: o.date ?? null,
  language: o.language ?? null,
  offerType: o.offerType ?? null,
  heading: o.heading ?? null,
  benefit: o.benefit ?? null,
  url: o.url ?? null,
  partner: o.partner ? {
    name: o.partner.name ?? null,
    analyticsPartnerId: o.partner.analyticsPartnerId ?? null,
    tag: o.partner.tag ?? null,
    logoSrc: o.partner.logo?.src ?? null,
  } : null,
  categoryTags: o.categoryTags ?? [],
}));

fs.writeFileSync(OUT, JSON.stringify({ offers: min }));
console.log(`✅ Wrote ${OUT} (${min.length} offers)`);
