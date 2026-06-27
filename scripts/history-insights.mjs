// scripts/history-insights.mjs
import fs from "node:fs";
import path from "node:path";

const DATA_DIR = process.env.DATA_DIR || "data";
const HISTORY_DIR = path.join(DATA_DIR, "history");

function readJson(p) {
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, "utf8")); }
  catch { return null; }
}

function listMonthIndexes() {
  if (!fs.existsSync(HISTORY_DIR)) return [];
  return fs.readdirSync(HISTORY_DIR)
    .filter(f => f.startsWith("_month_"))
    .map(f => readJson(path.join(HISTORY_DIR, f)))
    .filter(Boolean);
}

export function getInsightForShop(slug, currentPoints) {
  const months = listMonthIndexes();
  if (months.length === 0) return null;

  const history = [];
  for (const m of months) {
    const shop = m.shops?.[slug];
    if (shop) history.push({ month: m.month, maxPoints: shop.maxPoints });
  }
  if (history.length === 0) return null;

  const allTimeMax = Math.max(...history.map(h => h.maxPoints));
  const monthsTracked = history.length;
  let headline = "";
  let recommendation = "";

  if (currentPoints >= allTimeMax && monthsTracked >= 2) {
    headline = `📈 Høyeste på ${monthsTracked} måneder`;
    recommendation = "Sjelden så bra – book nå!";
  } else if (currentPoints >= allTimeMax * 0.9) {
    headline = `📊 Nær toppnivå (maks: ${allTimeMax}p)`;
    recommendation = "Godt tilbud akkurat nå";
  }

  const currentMonth = new Date().toISOString().slice(5, 7);
  const sameMonthHistory = history.filter(h => h.month.slice(5, 7) === currentMonth);
  if (sameMonthHistory.length >= 1 && monthsTracked >= 6) {
    headline = headline || `🗓️ Tilbakevendende kampanje`;
    recommendation = recommendation || "Pleier å ha kampanje denne tiden";
  }

  if (!headline) return null;
  return { headline, recommendation };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const slug = process.argv[2] || "outnorth";
  const pts = Number(process.argv[3] || 50);
  console.log(JSON.stringify(getInsightForShop(slug, pts), null, 2));
}
