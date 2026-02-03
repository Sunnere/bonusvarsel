// scripts/notify-from-changes.mjs
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { sendTelegram } from "./notify-telegram.mjs";

/* =========================
   Config (program scope)
========================= */

const PROGRAM = String(process.env.PROGRAM ?? "sas").toLowerCase();
const CHANNEL = String(process.env.CHANNEL ?? PROGRAM).toUpperCase(); // SAS/TURKISH/...
const COUNTRY = String(process.env.COUNTRY ?? "no").toLowerCase(); // no/se/...

const DISPLAY_NAME = String(process.env.DISPLAY_NAME ?? "").trim(); // f.eks "SAS EuroBonus"
const ALLIANCE = String(process.env.ALLIANCE ?? "").trim(); // f.eks "SkyTeam"

// Data directory (comes from workflow matrix)
const DATA_DIR = process.env.DATA_DIR
  ? path.resolve(process.env.DATA_DIR)
  : path.resolve("data");

const changesPath = path.join(DATA_DIR, "changes.json");
const summaryPath = path.join(DATA_DIR, "changes.summary.json");
const sentPath = path.join(DATA_DIR, "sent.json");


const SENT_TTL_DAYS = Number(process.env.SENT_TTL_DAYS ?? 30);

const META = {
  program: PROGRAM.toUpperCase(),
  country: COUNTRY,
  channel: CHANNEL,
};

/* =========================
   JSON helpers
========================= */
function readJson(p) {
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8"));
}
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n", "utf8");
}

/* =========================
   Dedupe helpers
========================= */
function sha1(s) {
  return crypto.createHash("sha1").update(String(s)).digest("hex");
}

function stableId(it) {
  return (
    it.id ??
    it.campaignId ??
    it.shopId ??
    it.merchantId ??
    it.slug ??
    it.url ??
    it.title ??
    "unknown"
  );
}

export function eventKey(it, meta = META) {
  const payload = {
    program: meta.program ?? it.program ?? "SAS",
    country: meta.country ?? it.country ?? "no",
    channel: meta.channel ?? it.channel ?? "SAS",
    kind: it.kind ?? "",
    type: it.type ?? "",
    id: String(stableId(it)),
    merchant: it.merchant ?? "",
    multiplier: it.multiplier ?? null,
    points: it.points ?? null,
    percent: it.percent ?? null,
    startsAt: it.startsAt ?? null,
    endsAt: it.endsAt ?? null,
    // NB: url kan gjøre dedupe for "følsom" hvis url endres ofte.
    // url: it.url ?? null,
  };
  return sha1(JSON.stringify(payload));
}

function loadSent() {
  return readJson(sentPath) ?? {};
}

function cleanupSent(sent, ttlDays = SENT_TTL_DAYS) {
  const now = Date.now();
  const ttlMs = ttlDays * 24 * 60 * 60 * 1000;

  for (const [k, v] of Object.entries(sent)) {
    // støtter både {sentAt} og "sentAt-string" fra gamle varianter
    const t = new Date(v?.sentAt ?? v ?? 0).getTime();
    if (!t || now - t > ttlMs) delete sent[k];
  }
  return sent;
}

function markSent(sent, keys) {
  const sentAt = new Date().toISOString();
  for (const k of keys) sent[k] = { sentAt };
}

/* =========================
   Build relevant items
========================= */
function buildRelevant(changes) {
  if (!changes) return [];
  const updated = (changes.updated || []).map((x) => ({ ...x, type: "updated" }));
  const added = (changes.added || []).map((x) => ({ ...x, type: "added" }));
  return [...updated, ...added];
}

/* =========================
   Message helpers (Telegram HTML)
========================= */
function escapeHtml(s) {
  return String(s ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function prettyDate(x) {
  if (!x) return "";
  const d = new Date(x);
  if (Number.isNaN(d.getTime())) return "";
  return d.toISOString().slice(0, 10); // YYYY-MM-DD
}

function formatPeriod(startsAt, endsAt) {
  const s = prettyDate(startsAt);
  const e = prettyDate(endsAt);
  if (s && e) return `${s} → ${e}`;
  if (s) return `Fra ${s}`;
  if (e) return `Til ${e}`;
  return "";
}

function linkLine(url, label) {
  if (!url) return "";
  return `• 🔗 <a href="${escapeHtml(url)}">${escapeHtml(label)}</a>`;
}

export function buildMessageHTML(items) {
  const now = new Date().toISOString().slice(0, 16).replace("T", " ");

  const headline = DISPLAY_NAME ? DISPLAY_NAME : META.program;
  const allianceLine = ALLIANCE ? `\n🤝 ${escapeHtml(ALLIANCE)}` : "";

  const header = `<b>🟡 BonusVarsel</b>\n<b>${escapeHtml(headline)}</b> (${escapeHtml(
    META.country.toUpperCase()
  )})${allianceLine}\n🕒 ${now}\n`;

  const campaigns = items.filter((x) => x.kind === "campaign");
  const shops = items.filter((x) => x.kind === "shop");

  const lines = [];
  lines.push(header);

  if (campaigns.length) {
    lines.push(`<b>🔥 Kampanjer (${campaigns.length})</b>`);
    for (const it of campaigns.slice(0, 12)) {
      const label = it.type === "added" ? "🆕 Ny" : "📈 Endret";
      const merchant = escapeHtml(it.merchant || it.title || "Ukjent");
      const rate = it.multiplier != null ? `${escapeHtml(it.multiplier)} poeng/kr` : "";
      const period = formatPeriod(it.startsAt, it.endsAt);

      lines.push(`${label}: <b>${merchant}</b>`);
      if (it.title && it.title !== it.merchant) lines.push(`• ${escapeHtml(it.title)}`);
      if (rate) lines.push(`• 🎁 ${rate}`);
      if (period) lines.push(`• 📅 ${escapeHtml(period)}`);
      if (it.url) lines.push(linkLine(it.url, "Åpne kampanje"));
      lines.push("");
    }
    if (campaigns.length > 12) {
      lines.push(`… +${campaigns.length - 12} flere kampanjer`);
      lines.push("");
    }
  }

  if (shops.length) {
    lines.push(`<b>🛍️ Butikker (${shops.length})</b>`);
    for (const it of shops.slice(0, 12)) {
      const label = it.type === "added" ? "🆕 Ny" : "🔁 Endret";
      const merchant = escapeHtml(it.merchant || it.title || "Ukjent");
      const rate = it.multiplier != null ? `${escapeHtml(it.multiplier)} poeng/kr` : "";

      lines.push(`${label}: <b>${merchant}</b>`);
      if (rate) lines.push(`• 🎁 ${rate}`);
      if (it.url) lines.push(linkLine(it.url, "Åpne butikk"));
      lines.push("");
    }
    if (shops.length > 12) {
      lines.push(`… +${shops.length - 12} flere butikker`);
      lines.push("");
    }
  }

  // fallback
  const joined = lines.join("\n").trim();
  if (joined === header.trim()) {
    lines.push("Ingen relevante kampanje-endringer nå. 💤");
  }

  // Telegram max ~4096 chars
  return lines.join("\n").trim().slice(0, 3500);
}

/* =========================
   Main
========================= */
async function main() {
  const force = process.argv.includes("--force");

  const changes = readJson(changesPath);
  const summary = readJson(summaryPath);

  if (!changes) {
    console.error(`Fant ikke ${changesPath}. Kjør collector først.`);
    process.exit(1);
  }

  const items = buildRelevant(changes);

  // pen logg (valgfritt)
  const cSum = summary?.campaigns?.summary;
  if (cSum) {
    console.log(`Campaigns: +${cSum.added ?? 0} / ~${cSum.updated ?? 0} / -${cSum.removed ?? 0}`);
  }

  // --- DEDUPE ---
  let sent = cleanupSent(loadSent());
  const unsent = items.filter((it) => !sent[eventKey(it, META)]);

  if (unsent.length === 0 && !force) {
    console.log("Ingen nye relevante endringer ✅ (dedupe, sender ikke)");
    // skriv tilbake ryddet sent (TTL)
    writeJson(sentPath, sent);
    return; // ✅ exit 0 / grønn
  }

  if (unsent.length === 0 && force) {
  const displayName = process.env.DISPLAY_NAME ?? META.program;
  const alliance = process.env.ALLIANCE ? ` • ${process.env.ALLIANCE}` : "";

  const msg =
    `<b>🟡 BonusVarsel</b>\n` +
    `<b>${displayName}${alliance}</b>\n\n` +
    `Ingen relevante kampanje-endringer nå. 💤`;

  await sendTelegram(msg);
  console.log("Sendte (force) ✅");
  return; // ✅ exit 0 / grønn
}

  // --- SEND ---
  const msg = buildMessageHTML(unsent);
  await sendTelegram(msg);

  // --- MARK SENT ---
  markSent(sent, unsent.map((it) => eventKey(it, META)));
  writeJson(sentPath, sent);

  console.log(`Sendt til Telegram ✅ (items=${unsent.length})`);
}

main().catch((e) => {
  console.error("Notify feilet ❌");
  console.error(e?.stack || e);
  process.exit(1); // ekte feil => rød
});