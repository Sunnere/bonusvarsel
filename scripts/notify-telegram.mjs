import fs from "node:fs";
import path from "node:path";

const TOKEN = process.env.TG_BOT_TOKEN;
const CHAT_ID = process.env.TG_CHAT_ID;

const messageOverride = process.argv.slice(2).join(" ").trim();

if (!TOKEN) {
  console.error("Mangler TG_BOT_TOKEN");
  process.exit(2);
}
if (!CHAT_ID) {
  console.error("Mangler TG_CHAT_ID");
  process.exit(2);
}

const SUMMARY_PATH = path.resolve("data", "changes.summary.json");

function readSummary() {
  if (!fs.existsSync(SUMMARY_PATH)) return null;
  return JSON.parse(fs.readFileSync(SUMMARY_PATH, "utf-8"));
}

function formatMessage(summary) {
  const c = summary?.campaigns || {};
  const s = summary?.shops || {};

  const changed =
    (c.added || 0) + (c.updated || 0) + (c.removed || 0) +
    (s.added || 0) + (s.updated || 0) + (s.removed || 0);

  if (!changed) return null;

  const lines = [
    "Bonusvarsel – endringer ✅",
    "",
    `Campaigns: +${c.added || 0} / ~${c.updated || 0} / -${c.removed || 0}`,
    `Shops:     +${s.added || 0} / ~${s.updated || 0} / -${s.removed || 0}`,
  ];

  return lines.join("\n");
}

async function sendTelegram(text) {
  const url = `https://api.telegram.org/bot${TOKEN}/sendMessage`;
  const body = new URLSearchParams({
    chat_id: String(CHAT_ID),
    text,
    disable_web_page_preview: "true",
  });

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });

  const json = await res.json().catch(() => ({}));
  if (!res.ok || !json.ok) {
    throw new Error(`Telegram API feil: HTTP ${res.status}\n${JSON.stringify(json, null, 2)}`);
  }
  return json;
}

async function main() {
  const summary = readSummary();
  if (!summary) {
    console.log("Fant ikke data/changes.summary.json – kjør collector først.");
    process.exit(0);
  }

if (messageOverride) {
  await sendTelegram(messageOverride);
  console.log("Sendte test/override-melding ✅");
  process.exit(0);
}

  const msg = formatMessage(summary);
  if (!msg) {
    console.log("Ingen endringer – sender ikke.");
    process.exit(0);
  }

  await sendTelegram(msg);
  console.log("Sendt til Telegram ✅");
}

main().catch((e) => {
  console.error("Notify feilet ❌");
  console.error(e?.stack || e);
  process.exit(1);
});
