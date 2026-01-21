import fs from "node:fs";
import path from "node:path";

const TOKEN = process.env.TG_BOT_TOKEN;
const CHAT_ID = process.env.TG_CHAT_ID;

if (!TOKEN) {
  console.error("❌ Mangler TG_BOT_TOKEN");
  process.exit(1);
}
if (!CHAT_ID) {
  console.error("❌ Mangler TG_CHAT_ID");
  process.exit(1);
}

const file = path.resolve("data/changes.summary.json");
const summary = JSON.parse(fs.readFileSync(file, "utf-8"));

function formatSummary(s) {
  return `
📣 *Bonusvarsel*

🛍 Kampanjer:
➕ Nye: ${s.campaigns.added}
✏️ Endret: ${s.campaigns.updated}
➖ Fjernet: ${s.campaigns.removed}

🏪 Butikker:
➕ Nye: ${s.shops.added}
✏️ Endret: ${s.shops.updated}
➖ Fjernet: ${s.shops.removed}
`.trim();
}

const text = formatSummary(summary);

await fetch(`https://api.telegram.org/bot${TOKEN}/sendMessage`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    chat_id: CHAT_ID,
    text,
    parse_mode: "Markdown",
  }),
});

console.log("Telegram-varsel sendt ✅");