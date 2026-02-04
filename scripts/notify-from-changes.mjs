// scripts/notify-from-changes.mjs
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { sendTelegram } from "./notify-telegram.mjs";

/**
 * Usage:
 *   node scripts/notify-from-changes.mjs
 *   node scripts/notify-from-changes.mjs --force
 *
 * Env (from workflow):
 *   PROGRAM, CHANNEL, COUNTRY
 *   DISPLAY_NAME, ALLIANCE
 *   DATA_DIR
 *   TG_BOT_TOKEN, TG_CHAT_ID
 *   SENT_TTL_DAYS (optional, default 30)
 */

const argv = process.argv.slice(2);
const FORCE = argv.includes("--force");

// Program scope (mostly for message text)
const PROGRAM = String(process.env.PROGRAM || "sas").toLowerCase();
const CHANNEL = String(process.env.CHANNEL || PROGRAM).toUpperCase();
const COUNTRY = String(process.env.COUNTRY || "no").toLowerCase();
const DISPLAY_NAME = String(process.env.DISPLAY_NAME || "").trim();
const ALLIANCE = String(process.env.ALLIANCE || "").trim();

// Data directory (comes from workflow matrix)
const DATA_DIR = String(process.env.DATA_DIR || "").trim();
if (!DATA_DIR) {
  throw new Error("DATA_DIR mangler. Sett DATA_DIR i workflow.");
}

const changesPath = path.join(DATA_DIR, "changes.json");
const summaryPath = path.join(DATA_DIR, "changes.summary.json");
const sentPath = path.join(DATA_DIR, "sent.json");

const SENT_TTL_DAYS = Number(process.env.SENT_TTL_DAYS || 30);

function readJson(p) {
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n", "utf8");
}

function sha1(text) {
  return crypto.createHash("sha1").update(text).digest("hex");
}

/**
 * sent.json format:
 * {
 *   "items": {
 *     "<hash>": { "ts": 1730000000000 }
 *   }
 * }
 */
function loadSent() {
  const data = readJson(sentPath);
  if (data && typeof data === "object" && data.items) return data;
  return { items: {} };
}

function pruneSent(sent) {
  const cutoff = Date.now() - SENT_TTL_DAYS * 24 * 60 * 60 * 1000;
  for (const [k, v] of Object.entries(sent.items || {})) {
    if (!v || typeof v.ts !== "number" || v.ts < cutoff) delete sent.items[k];
  }
}

function markSent(sent, hash) {
  sent.items[hash] = { ts: Date.now() };
}

function toTitle() {
  const name = DISPLAY_NAME || PROGRAM.toUpperCase();
  const bits = [];
  if (ALLIANCE) bits.push(ALLIANCE);
  bits.push(`${COUNTRY.toUpperCase()}`);
  return `${name} (${bits.join(" • ")})`;
}

function formatSummary(summary, changes) {
  // Prefer summary file if it exists
  if (summary && typeof summary === "object") {
    // Try common shapes
    if (typeof summary.text === "string" && summary.text.trim()) return summary.text.trim();
    if (typeof summary.message === "string" && summary.message.trim()) return summary.message.trim();
    if (Array.isArray(summary.lines) && summary.lines.length) return summary.lines.join("\n");
  }

  // Fallback: build a tiny readable message from changes.json
  const adds = (changes?.campaigns?.added?.length || 0) + (changes?.shops?.added?.length || 0);
  const upd = (changes?.campaigns?.updated?.length || 0) + (changes?.shops?.updated?.length || 0);
  const rem = (changes?.campaigns?.removed?.length || 0) + (changes?.shops?.removed?.length || 0);

  return `Endringer: +${adds} / ~${upd} / -${rem}`;
}

function hasRelevantChanges(changes) {
  // Adjust this if you later want “only campaigns” etc.
  const c = changes?.campaigns;
  const s = changes?.shops;

  const any =
    (c?.added?.length || 0) +
      (c?.updated?.length || 0) +
      (c?.removed?.length || 0) +
      (s?.added?.length || 0) +
      (s?.updated?.length || 0) +
      (s?.removed?.length || 0) >
    0;

  return Boolean(any);
}

async function main() {
  console.log(`Run ARGS="${FORCE ? "--force" : ""}"`);
  console.log(`DATA_DIR=${DATA_DIR}`);
  console.log(`PROGRAM=${PROGRAM} CHANNEL=${CHANNEL} COUNTRY=${COUNTRY}`);

  // Guard: if changes.json is missing, do NOT fail workflow
  if (!fs.existsSync(changesPath)) {
    console.log(`Fant ikke ${changesPath}. Ingen endringer å sende.`);
    process.exit(0);
  }

  const changes = readJson(changesPath) || {};
  const summary = readJson(summaryPath);

  const relevant = hasRelevantChanges(changes);
  if (!relevant && !FORCE) {
    console.log("Ingen relevante kampanje-endringer ✅ (sender ikke)");
    process.exit(0);
  }

  const title = toTitle();
  const body = formatSummary(summary, changes);

  // Unique key so we don’t spam same message repeatedly
  const messageText = `🔔 <b>${title}</b>\n${body}`;
  const messageHash = sha1(`${DATA_DIR}::${messageText}`);

  const sent = loadSent();
  pruneSent(sent);

  if (!FORCE && sent.items[messageHash]) {
    console.log("Allerede sendt nylig (dupe) ✅ (sender ikke)");
    process.exit(0);
  }

  const token = process.env.TG_BOT_TOKEN;
  const chatId = process.env.TG_CHAT_ID;

  await sendTelegram({
    token,
    chatId,
    text: messageText,
  });

  markSent(sent, messageHash);
  writeJson(sentPath, sent);

  console.log("Telegram sendt ✅");
}

main().catch((err) => {
  console.error("Notify feilet ❌");
  console.error(err?.stack || err?.message || err);
  process.exit(1);
});