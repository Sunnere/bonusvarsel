import fs from "node:fs";
import path from "node:path";

function readJson(p) {
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n", "utf8");
}

function pickFirst(...vals) {
  for (const v of vals) if (v != null && String(v).trim() !== "") return v;
  return null;
}

function buildProgramFeed(program = "sas") {
  const baseDir = "data";

  const campaigns =
    readJson(path.join(baseDir, "campaigns.normalized.json")) ??
    readJson(path.join(baseDir, "campaigns.raw.json")) ??
    [];

  const shops =
    readJson(path.join(baseDir, "shops.normalized.json")) ??
    readJson(path.join(baseDir, "shops.raw.json")) ??
    [];

  const items = [];

  for (const c of campaigns) {
    items.push({
      kind: "campaign",
      program,
      merchant: pickFirst(c.merchant, c.shopName, c.name, c.title),
      title: pickFirst(c.title, c.name),
      multiplier: pickFirst(c.multiplier, c.pointsPerKr),
      startsAt: pickFirst(c.startsAt, c.startDate),
      endsAt: pickFirst(c.endsAt, c.endDate),
      url: pickFirst(c.url, c.link),
      id: pickFirst(c.id, c.uuid),
    });
  }

  for (const s of shops) {
    items.push({
      kind: "shop",
      program,
      merchant: pickFirst(s.merchant, s.name, s.title),
      multiplier: pickFirst(s.multiplier, s.pointsPerKr),
      url: pickFirst(s.url, s.link),
      id: pickFirst(s.id, s.uuid),
    });
  }

  return {
    program,
    generatedAt: new Date().toISOString(),
    counts: {
      campaigns: campaigns.length,
      shops: shops.length,
      total: items.length,
    },
    items,
  };
}

function main() {
  const feed = buildProgramFeed("sas");
  writeJson("data/app.feed.json", feed);
  console.log("Wrote: data/app.feed.json");
  console.log(feed.counts);
}

main();
