// scripts/build-app-feed-all.mjs
import fs from "node:fs";
import path from "node:path";

function exists(p) {
  try {
    fs.accessSync(p);
    return true;
  } catch {
    return false;
  }
}

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n", "utf8");
}

function pickDataDir(baseDir, program) {
  const candidate = path.join(baseDir, program);

  // Normal layout: data/<program>/shops.normalized.json
  if (exists(path.join(candidate, "shops.normalized.json"))) return candidate;

  // Fallback: legacy layout for SAS: data/shops.normalized.json
  if (program === "sas" && exists(path.join(baseDir, "shops.normalized.json"))) return baseDir;

  return null;
}

function normalizeProgramMeta(program) {
  const p = String(program).toLowerCase();

  // Du kan justere display/alliance senere uten å endre appen
  if (p === "sas")
    return { program: "sas", displayName: "SAS EuroBonus", alliance: "SkyTeam", country: "no", channel: "SAS" };
  if (p === "turkish")
    return { program: "turkish", displayName: "Turkish Miles&Smiles", alliance: "Star Alliance", country: "no", channel: "TURKISH" };
  if (p === "lufthansa")
    return { program: "lufthansa", displayName: "Lufthansa Miles & More", alliance: "Star Alliance", country: "no", channel: "LUFTHANSA" };

  return { program: p, displayName: p.toUpperCase(), alliance: "", country: "no", channel: p.toUpperCase() };
}

function pickFieldsShop(s) {
  return {
    id: s.id ?? s.shopId ?? s.slug ?? s.url ?? s.name ?? null,
    merchant: s.merchant ?? s.name ?? s.title ?? null,
    multiplier: s.multiplier ?? s.pointsPerKr ?? s.points_per_kr ?? null,
    url: s.url ?? null,
    logo: s.logo ?? s.image ?? s.icon ?? null,
    categories: s.categories ?? s.category ?? [],
  };
}

function pickFieldsCampaign(c) {
  return {
    id: c.id ?? c.campaignId ?? c.slug ?? c.url ?? c.title ?? null,
    merchant: c.merchant ?? c.shopName ?? c.name ?? null,
    title: c.title ?? null,
    multiplier: c.multiplier ?? c.pointsPerKr ?? c.points_per_kr ?? null,
    url: c.url ?? null,
    startsAt: c.startsAt ?? c.starts_at ?? null,
    endsAt: c.endsAt ?? c.ends_at ?? null,
  };
}

function isActiveCampaign(c) {
  const now = Date.now();
  const s = c.startsAt ? new Date(c.startsAt).getTime() : null;
  const e = c.endsAt ? new Date(c.endsAt).getTime() : null;

  if (s && Number.isFinite(s) && now < s) return false; // ikke startet
  if (e && Number.isFinite(e) && now > e) return false; // utløpt
  return true;
}

function sortCampaigns(a, b) {
  // prioriter:
  // 1) aktive først
  // 2) høyest multiplier
  // 3) tidligst slutt (snart utløper)
  const aa = isActiveCampaign(a) ? 0 : 1;
  const bb = isActiveCampaign(b) ? 0 : 1;
  if (aa !== bb) return aa - bb;

  const am = Number(a.multiplier ?? 0);
  const bm = Number(b.multiplier ?? 0);
  if (bm !== am) return bm - am;

  const ae = a.endsAt ? new Date(a.endsAt).getTime() : Infinity;
  const be = b.endsAt ? new Date(b.endsAt).getTime() : Infinity;
  return ae - be;
}

async function main() {
  const baseDir = path.resolve(process.env.DATA_BASE_DIR ?? "data");
  const programs = String(process.env.PROGRAMS ?? "sas,turkish,lufthansa")
    .split(",")
    .map((x) => x.trim().toLowerCase())
    .filter(Boolean);

  const outFile = path.resolve(process.env.OUT_FILE ?? "data/app.feed.all.json");

  const out = {
    schema: "bonusvarsel.feed.v1",
    generatedAt: new Date().toISOString(),
    programs: {},
  };

  for (const program of programs) {
    const meta = normalizeProgramMeta(program);
    const dir = pickDataDir(baseDir, program);

    if (!dir) {
      console.log(`⚠️  Hopper over ${program}: fant ikke data i ${path.join(baseDir, program)} (eller base)`);
      continue;
    }

    const shopsPath = path.join(dir, "shops.normalized.json");
    const campaignsPath = path.join(dir, "campaigns.normalized.json");
    const lastRunPath = path.join(dir, "lastRun.json");

    const shopsRaw = exists(shopsPath) ? readJson(shopsPath) : [];
    const campaignsRaw = exists(campaignsPath) ? readJson(campaignsPath) : [];
    const lastRun = exists(lastRunPath) ? readJson(lastRunPath) : null;

    const shops = Array.isArray(shopsRaw) ? shopsRaw.map(pickFieldsShop) : [];
    const campaigns = Array.isArray(campaignsRaw) ? campaignsRaw.map(pickFieldsCampaign) : [];

    const campaignsActive = campaigns.filter(isActiveCampaign).sort(sortCampaigns);

    out.programs[program] = {
      meta,
      dataDir: path.relative(process.cwd(), dir),
      lastRun,
      totals: {
        shops: shops.length,
        campaigns: campaigns.length,
        campaignsActive: campaignsActive.length,
      },
      // Appen trenger ofte bare aktive kampanjer + butikker
      campaignsActive: campaignsActive.slice(0, 300),
      shops: shops.slice(0, 1000),
    };

    console.log(
      `✅ ${program}: shops=${shops.length}, campaigns=${campaigns.length}, active=${campaignsActive.length} (dir=${path.relative(process.cwd(), dir)})`
    );
  }

  writeJson(outFile, out);

  const keys = Object.keys(out.programs);
  console.log(`\nDone ✅ Wrote: ${path.relative(process.cwd(), outFile)}`);
  console.log(`Programs included: ${keys.length ? keys.join(", ") : "(none)"}`);
}

main().catch((e) => {
  console.error("Build feed feilet ❌");
  console.error(e?.stack || e);
  process.exit(1);
});