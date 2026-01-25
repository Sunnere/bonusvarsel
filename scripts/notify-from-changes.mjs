import fs from "node:fs";
import path from "node:path";

import { sendTelegram } from "./notify-telegram.mjs";

// Leser output fra collector
const CHANGES_PATH = path.resolve("data", "changes.json");

// --- helpers ---
function safeNumber(x) {
  if (x === null || x === undefined) return null;
  if (typeof x === "number") return Number.isFinite(x) ? x : null;
  if (typeof x === "string") {
    const v = Number(x.replace(",", "."));
    return Number.isFinite(v) ? v : null;
  }
  return null;
}

// Prøv å hente "poeng/kr" eller liknende fra ulike felter (fordi API kan variere)
function getMultiplier(obj) {
  // vanlige feltvarianter
  return (
    safeNumber(obj?.multiplier) ??
    safeNumber(obj?.pointsPerKr) ??
    safeNumber(obj?.points_per_kr) ??
    safeNumber(obj?.rate) ??
    safeNumber(obj?.value) ??
    null
  );
}

function getTitle(obj) {
  return (
    obj?.title ??
    obj?.name ??
    obj?.merchantName ??
    obj?.merchant ??
    obj?.shopName ??
    "Ukjent"
  );
}

function getUrl(obj) {
  return obj?.url ?? obj?.link ?? obj?.href ?? null;
}

function parseDateMaybe(x) {
  if (!x) return null;
  const d = new Date(x);
  return Number.isNaN(d.getTime()) ? null : d;
}

function isUpcoming(obj) {
  // Dersom vi har startsAt, så er kampanjen "kommende" hvis den starter frem i tid
  const starts = parseDateMaybe(obj?.startsAt ?? obj?.startAt ?? obj?.start_date);
  if (!starts) return false;
  return starts.getTime() > Date.now();
}

function fmtDateShort(d) {
  if (!d) return "";
  // Norsk-ish kort format
  return d.toLocaleDateString("nb-NO", { day: "2-digit", month: "2-digit" });
}

function formatCampaignLine({ label, title, beforeMult, afterMult, url, upcoming, startsAt }) {
  const parts = [];
  parts.push(label);

  // Title (butikk)
  parts.push(`*${escapeMd(title)}*`);

  // multiplier
  if (beforeMult !== null && afterMult !== null) {
    parts.push(`_${beforeMult}→${afterMult} poeng/kr_`);
  } else if (afterMult !== null) {
    parts.push(`_${afterMult} poeng/kr_`);
  }

  // upcoming
  if (upcoming) {
    const d = startsAt ? fmtDateShort(startsAt) : "";
    parts.push(d ? `⏳ starter ${d}` : `⏳ kommende`);
  }

  // url
  if (url) parts.push(url);

  return parts.join(" — ");
}

// Telegram MarkdownV2 escape (basic)
function escapeMd(text) {
  return String(text).replace(/[_*[\]()~`>#+\-=|{}.!]/g, "\\$&");
}

function readChanges() {
  if (!fs.existsSync(CHANGES_PATH)) return null;
  return JSON.parse(fs.readFileSync(CHANGES_PATH, "utf-8"));
}

function buildMessage({ increasedUpdated, upcomingAdded }) {
  const lines = [];

  lines.push("🎯 *Bonusvarsel*");
  lines.push("");

  if (increasedUpdated.length) {
    lines.push("📈 *Økte kampanjer*");
    for (const item of increasedUpdated) {
      lines.push(item.line);
    }
    lines.push("");
  }

  if (upcomingAdded.length) {
    lines.push("⏳ *Kommende kampanjer*");
    for (const item of upcomingAdded) {
      lines.push(item.line);
    }
    lines.push("");
  }

  // litt footer
  lines.push(`Oppdatert: ${new Date().toLocaleString("nb-NO")}`);

  return lines.join("\n");
}

// --- main ---
async function main() {
  const args = process.argv.slice(2);
  const force = args.includes("--force") || args.includes("-f");

  const changes = readChanges();
  if (!changes) {
    console.log(`Fant ikke ${CHANGES_PATH}. Kjør collector først.`);
    process.exit(1);
  }

  const campaigns = changes?.campaigns ?? {};
  const added = Array.isArray(campaigns.added) ? campaigns.added : [];
  const updated = Array.isArray(campaigns.updated) ? campaigns.updated : [];

  // 1) "Økte" = updated der multiplier går opp
  const increasedUpdated = updated
    .map((u) => {
      const beforeObj = u?.before ?? u?.old ?? null;
      const afterObj = u?.after ?? u?.new ?? null;

      const beforeMult = getMultiplier(beforeObj);
      const afterMult = getMultiplier(afterObj);

      const title = getTitle(afterObj || beforeObj);
      const url = getUrl(afterObj || beforeObj);

      if (beforeMult === null || afterMult === null) return null;
      if (!(afterMult > beforeMult)) return null;

      return {
        title,
        beforeMult,
        afterMult,
        url,
        line: formatCampaignLine({
          label: "•",
          title,
          beforeMult,
          afterMult,
          url,
          upcoming: false,
          startsAt: null,
        }),
      };
    })
    .filter(Boolean);

  // 2) "Kommende" = added der startsAt er i fremtiden
  const upcomingAdded = added
    .map((a) => {
      // added kan være { after: {...} } eller bare objektet
      const obj = a?.after ?? a?.new ?? a;
      const title = getTitle(obj);
      const url = getUrl(obj);

      const mult = getMultiplier(obj);
      const startsAt = parseDateMaybe(obj?.startsAt ?? obj?.startAt ?? obj?.start_date);

      if (!isUpcoming(obj)) return null;

      return {
        title,
        afterMult: mult,
        url,
        startsAt,
        line: formatCampaignLine({
          label: "•",
          title,
          beforeMult: null,
          afterMult: mult,
          url,
          upcoming: true,
          startsAt,
        }),
      };
    })
    .filter(Boolean);

  const hasRelevant = increasedUpdated.length > 0 || upcomingAdded.length > 0;

  if (!hasRelevant && !force) {
    console.log("Ingen relevante kampanje-endringer (kun økt/kommende) ✅");
    process.exit(0);
  }

  const msg = hasRelevant
    ? buildMessage({ increasedUpdated, upcomingAdded })
    : `🧪 *Bonusvarsel test* (force)\n\nOppdatert: ${new Date().toLocaleString("nb-NO")}`;

  await sendTelegram(msg);
  console.log("Sendt til Telegram ✅");
}

main().catch((e) => {
  console.error("Notify feilet ❌");
  console.error(e?.stack || e);
  process.exit(1);
});
