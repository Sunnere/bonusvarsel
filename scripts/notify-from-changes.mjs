import fs from "node:fs";
import path from "node:path";
import { sendTelegram } from "./notify-telegram.mjs";

const changesPath = path.resolve("data", "changes.json");
const summaryPath = path.resolve("data", "changes.summary.json");

// --- helpers ---
function readJson(p) {
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function asDate(v) {
  if (!v) return null;
  const d = new Date(v);
  return Number.isFinite(d.getTime()) ? d : null;
}

function toNumberMaybe(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string") {
    // handle "12", "12.5", "12,5", "+20", "20 poeng/kr"
    const cleaned = v
      .trim()
      .replace(",", ".")
      .replace(/[^\d.+-]/g, "");
    const n = Number(cleaned);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function pickAfter(obj) {
  // changes.json kan ha {after}, {new}, eller objektet selv
  return obj?.after ?? obj?.new ?? obj;
}

function pickBefore(obj) {
  return obj?.before ?? obj?.old ?? null;
}

function getTitle(x) {
  return (
    x?.title ||
    x?.merchant ||
    x?.merchantName ||
    x?.name ||
    x?.shop ||
    x?.store ||
    "Ukjent"
  );
}

function getUrl(x) {
  return x?.url || x?.link || x?.href || null;
}

function getStart(x) {
  return asDate(x?.startsAt || x?.startAt || x?.start || x?.validFrom);
}

function getEnd(x) {
  return asDate(x?.endsAt || x?.endAt || x?.end || x?.validTo);
}

function getRate(x) {
  // Prøver å finne “rate”/multiplier/poeng per kr i vanlige felter
  const candidates = [
    x?.multiplier,
    x?.pointsPerKr,
    x?.points_per_kr,
    x?.pointsPerCurrency,
    x?.points,
    x?.bonus,
    x?.rate,
    x?.value,
  ];
  for (const c of candidates) {
    const n = toNumberMaybe(c);
    if (n !== null) return n;
  }
  return null;
}

function formatRate(n) {
  if (n === null) return "";
  // Vi antar "poeng/kr" i output (det matcher prosjektet ditt)
  // Hvis du heller vil ha "x" multiplier, si fra så endrer vi.
  const isInt = Number.isInteger(n);
  return `${isInt ? n : n.toFixed(1)} poeng/kr`;
}

function formatDateShort(d) {
  if (!d) return "";
  // yyyy-mm-dd -> dd.mm
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}`;
}

function shorten(s, max = 42) {
  if (!s) return "";
  const t = String(s).trim();
  return t.length <= max ? t : `${t.slice(0, max - 1)}…`;
}

function lineForCampaign({ kind, title, beforeRate, afterRate, start, url }) {
  const name = shorten(title, 44);
  const when = start ? ` (fra ${formatDateShort(start)})` : "";
  const arrow =
    beforeRate !== null && afterRate !== null && afterRate > beforeRate
      ? ` ${formatRate(beforeRate)} → ${formatRate(afterRate)}`
      : afterRate !== null
      ? ` ${formatRate(afterRate)}`
      : "";

  // Telegram: lenke på egen linje kan bli stygt, så vi gjør "Navn — rate" + url på slutten hvis finnes
  const base = `${kind} ${name}${arrow}${when}`;
  return url ? `${base}\n${url}` : base;
}

// --- main logic ---
function buildRelevant(changes) {
  const now = new Date();

  const added = (changes?.campaigns?.added || []).map(pickAfter);
  const updatedPairs = changes?.campaigns?.updated || [];

  // Ny (added): send hvis den starter i fremtiden (kommende) eller starter nå/allerede (ny)
  const relevantAdded = added
    .map((c) => {
      const start = getStart(c);
      return {
        kind: start && start > now ? "🔜" : "🆕",
        title: getTitle(c),
        beforeRate: null,
        afterRate: getRate(c),
        start,
        url: getUrl(c),
      };
    })
    .filter((x) => x.title);

  // Oppdatert: send bare hvis “rate” har økt, eller startdato er frem i tid (kommende oppdatering)
  const relevantUpdated = updatedPairs
    .map((pair) => {
      const before = pickBefore(pair);
      const after = pickAfter(pair);
      const bRate = getRate(before);
      const aRate = getRate(after);
      const start = getStart(after) || getStart(before);
      const increased =
        bRate !== null && aRate !== null ? aRate > bRate : false;

      const upcoming = start && start > now;

      if (!increased && !upcoming) return null;

      return {
        kind: increased ? "📈" : "🔜",
        title: getTitle(after) || getTitle(before),
        beforeRate: increased ? bRate : null,
        afterRate: aRate,
        start,
        url: getUrl(after) || getUrl(before),
      };
    })
    .filter(Boolean);

  // Prioritering: økninger først, så nye, så kommende
  const score = (x) => {
    if (x.kind === "📈") return 3;
    if (x.kind === "🆕") return 2;
    if (x.kind === "🔜") return 1;
    return 0;
  };

  const all = [...relevantUpdated, ...relevantAdded].sort(
    (a, b) => score(b) - score(a)
  );

  return all;
}

function buildMessage(items) {
  const header = "🟡 BonusVarsel – nye/økte/kommende kampanjer";

  // Maks antall “kampanje-blokker” (hver blokk kan ha 1–2 linjer pga URL)
  const maxItems = 8;
  const selected = items.slice(0, maxItems);

  const lines = selected.flatMap((x) => {
    const block = lineForCampaign(x);
    return block.split("\n");
  });

  // Telegram har meldingslimit, men dette er trygt lavt
  const body = lines.join("\n");
  return `${header}\n\n${body}`.trim();
}

async function main() {
  const force = process.argv.includes("--force");

  const changes = readJson(changesPath);
  const summary = readJson(summaryPath);

  if (!changes) {
    console.error(`Fant ikke ${changesPath}. Kjør collector først.`);
    process.exit(1);
  }

  const items = buildRelevant(changes);

  // Litt pen logg i terminalen (ikke spam)
  const cSum = summary?.campaigns?.summary;
  if (cSum) {
    console.log(
      `Campaigns: +${cSum.added ?? 0} / ~${cSum.updated ?? 0} / -${
        cSum.removed ?? 0
      }`
    );
  }

  if (items.length === 0 && !force) {
    console.log("Ingen relevante kampanje-endringer ✅ (sender ikke)");
    process.exit(0);
  }

  if (items.length === 0 && force) {
    await sendTelegram("🟡 BonusVarsel\n\nIngen relevante kampanje-endringer nå.");
    console.log("Sendte (force) ✅");
    process.exit(0);
  }

  const msg = buildMessage(items);
  await sendTelegram(msg);
  console.log("Sendt til Telegram ✅");
}

main().catch((e) => {
  console.error("Notify feilet ❌");
  console.error(e?.stack || e);
  process.exit(1);
});