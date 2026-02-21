// scripts/build-app-feed.mjs
import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const DATA_ROOT = path.join(ROOT, "data");

// hvilke programmer du vil ha med i feed (matcher mappene dine)
const PROGRAMS = [
  { key: "sas", dir: path.join(DATA_ROOT, "sas"), display: "SAS EuroBonus", alliance: "SkyTeam" },
  { key: "turkish", dir: path.join(DATA_ROOT, "turkish"), display: "Turkish Miles&Smiles", alliance: "Star Alliance" },
  { key: "lufthansa", dir: path.join(DATA_ROOT, "lufthansa"), display: "Lufthansa Miles & More", alliance: "Star Alliance" },
];

function readJson(p) {
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function safeArray(v) {
  return Array.isArray(v) ? v : (v?.items && Array.isArray(v.items) ? v.items : []);
}

function statMtime(p) {
  try {
    return fs.statSync(p).mtimeMs;
  } catch {
    return null;
  }
}

function getProgramPayload(p) {
  const campaignsPath = path.join(p.dir, "campaigns.normalized.json");
  const shopsPath = path.join(p.dir, "shops.normalized.json");
  const changesPath = path.join(p.dir, "changes.summary.json");

  const campaigns = readJson(campaignsPath);
  const shops = readJson(shopsPath);
  const changes = readJson(changesPath);

  const updatedAtMs = Math.max(
    statMtime(campaignsPath) ?? 0,
    statMtime(shopsPath) ?? 0,
    statMtime(changesPath) ?? 0
  );

  return {
    program: p.key,
    displayName: p.display,
    alliance: p.alliance,
    updatedAt: updatedAtMs ? new Date(updatedAtMs).toISOString() : null,
    counts: {
      campaigns: safeArray(campaigns).length,
      shops: safeArray(shops).length,
      changes: safeArray(changes).length,
    },
    data: {
      campaigns: safeArray(campaigns),
      shops: safeArray(shops),
      changes: safeArray(changes),
    },
  };
}

function main() {
  const programs = PROGRAMS
    .filter(p => fs.existsSync(p.dir))
    .map(getProgramPayload);

  const feed = {
    version: 1,
    generatedAt: new Date().toISOString(),
    programs,
  };

  const outPath = path.join(DATA_ROOT, "app-feed.json");
  fs.mkdirSync(DATA_ROOT, { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(feed, null, 2) + "\n", "utf8");

  console.log("✅ Wrote", outPath);
  console.log("Programs:", programs.map(p => `${p.program} (shops=${p.counts.shops}, campaigns=${p.counts.campaigns}, changes=${p.counts.changes})`).join(" | "));
}

main();