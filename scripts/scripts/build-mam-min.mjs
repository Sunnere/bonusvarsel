import fs from "node:fs";
import path from "node:path";

const SRC = "assets/mam.offers.json";
const OUT = "assets/mam.offers.min.json";

const keep = (o) => ({
  id: o.id ?? null,
  date: o.date ?? null,
  language: o.language ?? null,
  offerType: o.offerType ?? null,
  heading: o.heading ?? null,
  benefit: o.benefit ?? null,
  url: o.url ?? null,

  partner: o.partner
    ? {
        name: o.partner.name ?? null,
        analyticsPartnerId: o.partner.analyticsPartnerId ?? null,
        tag: o.partner.tag ?? null,
        logoSrc: o.partner.logo?.src ?? null,
      }
    : null,

  categoryTags: o.categoryTags ?? [],
  entityTags: o.entityTags ?? [],
  editorialTags: o.editorialTags ?? [],
});

const raw = fs.readFileSync(SRC, "utf8");
const j = JSON.parse(raw);

if (!Array.isArray(j.offers)) {
  throw new Error(`Expected { offers: [] } in ${SRC}`);
}

const min = j.offers.map(keep);

// skriv kompakt (ingen pretty print)
fs.writeFileSync(OUT, JSON.stringify({ offers: min }));
console.log(`Wrote ${OUT} (${min.length} offers)`);
