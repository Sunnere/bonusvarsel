// Flying Agent – AI-agent for fly og lojalitetsprogrammer (SAS/SkyTeam, Norwegian, Flying Blue, Avios).
// Eksporteres fra functions/index.js som: exports.flyingAgent
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const MODEL = "claude-sonnet-5";
const MAX_TOKENS = 1200;
const MAX_MESSAGES = 20;
const MAX_CONTENT_CHARS = 4000;
const MAX_CONTEXT_CHARS = 800;
const MAX_CONTINUATIONS = 3;

// Daglig grense per bruker (spørsmål/dag). Endre her.
const DAILY_LIMITS = { free: 3, premium: 15, pro: 15, elite: 30 };

const SEARCH_DOMAINS = [
  "flysas.com", "sas.no", "sas.se", "ba.com", "britishairways.com",
  "airfrance.com", "airfrance.no", "klm.com", "klm.no", "flyingblue.com",
  "norwegian.com", "skyteam.com", "americanexpress.com", "americanexpress.no",
  "trumf.no", "trumfnetthandel.no", "scandichotels.no", "scandichotels.com", "thonhotels.no",
  "radissonhotels.com", "hertz.no", "avis.no", "sixt.no", "budget.no",
  "eurobonusguiden.no", "sparelosen.no",
];

let _kb = null;
function loadKb() {
  if (_kb === null) {
    _kb = fs.readFileSync(path.join(__dirname, "flying_agent_kb.md"), "utf8");
  }
  return _kb;
}

function osloDate(now = new Date()) {
  return new Intl.DateTimeFormat("sv-SE", { timeZone: "Europe/Oslo" }).format(now); // YYYY-MM-DD
}

function sanitizeMessages(raw) {
  if (!Array.isArray(raw)) return [];
  let msgs = raw
    .filter((m) => m && (m.role === "user" || m.role === "assistant") && typeof m.content === "string")
    .map((m) => ({ role: m.role, content: m.content.trim().slice(0, MAX_CONTENT_CHARS) }))
    .filter((m) => m.content.length > 0 && !m.content.startsWith("❌"));
  msgs = msgs.slice(-MAX_MESSAGES);
  while (msgs.length && msgs[0].role !== "user") msgs.shift();
  // Slå sammen etterfølgende meldinger med samme rolle (API krever veksling)
  const merged = [];
  for (const m of msgs) {
    const last = merged[merged.length - 1];
    if (last && last.role === m.role) last.content += "\n\n" + m.content;
    else merged.push({ ...m });
  }
  return merged;
}

function buildSystem({ lang, context, today }) {
  const answerLang = lang === "en" ? "Answer in English." : "Svar på norsk.";
  const ctx = context ? `\n\nBrukerens lagrede saldoer (oppgitt av bruker, ikke verifisert):\n${context}` : "";
  return [
    "Du er Flying Agent i Bonusvarsel-appen: en ekspert på flyreiser og lojalitetsprogrammer – SAS EuroBonus, SkyTeam, Norwegian Reward/CashPoints, Flying Blue og British Airways Avios, samt Trumf-bonus og Spenn (Norwegian og Strawberry), Amex-poeng som kan overføres, og hvordan man tjener og bruker poeng på hotell og bilutleie.",
    answerLang,
    `Dagens dato: ${today}. Brukeren er normalt i Norge og tenker i NOK.`,
    "Regler: Aldri dikt opp poengkrav, priser, regler eller tilgjengelighet. Hvis du ikke har det i kunnskapsbasen eller fra nettsøk, si det og vis hvor brukeren kan sjekke. Fakta merket [?] eller [Roy] i kunnskapsbasen skal omtales som anslag som må bekreftes. Du kan ikke se ledige seter eller logge inn noe sted. Hold svarene korte og konkrete (helst under 200 ord), uten overdreven formatering. Oppgi kildene du brukte fra nettsøk.",
    "Kunnskapsbase:\n" + loadKb() + ctx,
  ].join("\n\n");
}

function extractText(content) {
  const blocks = Array.isArray(content) ? content : [];
  const text = blocks.filter((b) => b.type === "text").map((b) => b.text).join("");
  const urls = new Map();
  for (const b of blocks) {
    if (b.type !== "text" || !Array.isArray(b.citations)) continue;
    for (const c of b.citations) {
      if (c && c.url && !urls.has(c.url)) urls.set(c.url, c.title || c.url);
    }
  }
  return { text: text.trim(), sources: [...urls.entries()].slice(0, 3) };
}

function formatReply({ text, sources }) {
  if (!sources.length) return text;
  return text + "\n\nKilder:\n" + sources.map(([u, t]) => `- ${t} (${u})`).join("\n");
}

async function getPlan(db, uid) {
  try {
    const doc = await db.collection("subscriptions").doc(uid).get();
    if (!doc.exists) return "free";
    const d = doc.data() || {};
    if (d.source === "google_play" && d.playExpiryTime && d.playExpiryTime.toMillis() < Date.now()) return "free";
    if (d.source === "app_store" && d.appStoreExpiryTime && d.appStoreExpiryTime.toMillis() < Date.now()) return "free";
    return d.plan || "free";
  } catch (e) {
    return "free";
  }
}

// Atomisk teller. Returnerer { ok, used, limit }.
async function takeQuota(db, uid, plan, now = new Date()) {
  const limit = DAILY_LIMITS[plan] ?? DAILY_LIMITS.free;
  const ref = db.collection("flying_agent_usage").doc(`${uid}_${osloDate(now)}`);
  const res = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const used = snap.exists ? snap.data().count || 0 : 0;
    if (used >= limit) return { ok: false, used, limit };
    tx.set(ref, { uid, count: used + 1, plan, updatedAt: new Date() }, { merge: true });
    return { ok: true, used: used + 1, limit };
  });
  return { ...res, ref };
}

async function refundQuota(db, ref) {
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const c = snap.exists ? snap.data().count || 0 : 0;
      if (c > 0) tx.set(ref, { count: c - 1 }, { merge: true });
    });
  } catch (e) { /* best effort */ }
}

async function callAnthropic(fetchFn, apiKey, system, messages, useSearch) {
  const convo = messages.map((m) => ({ role: m.role, content: m.content }));
  let lastContent = [];
  for (let i = 0; i < MAX_CONTINUATIONS; i++) {
    const body = {
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: [{ type: "text", text: system, cache_control: { type: "ephemeral" } }],
      messages: convo,
    };
    if (useSearch) {
      body.tools = [{
        type: "web_search_20250305", name: "web_search", max_uses: 3,
        allowed_domains: SEARCH_DOMAINS,
        user_location: { type: "approximate", country: "NO", timezone: "Europe/Oslo" },
      }];
    }
    const r = await fetchFn("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-api-key": apiKey, "anthropic-version": "2023-06-01" },
      body: JSON.stringify(body),
    });
    if (!r.ok) {
      const err = await r.text();
      const e = new Error(`Anthropic ${r.status}: ${err.slice(0, 300)}`);
      e.status = r.status;
      e.body = err;
      throw e;
    }
    const j = await r.json();
    lastContent = j.content || [];
    if (j.stop_reason === "pause_turn") {
      convo.push({ role: "assistant", content: lastContent });
      continue;
    }
    break;
  }
  return lastContent;
}

function makeHandler({ getDb, fetchFn, now = () => new Date() }) {
  return async (request) => {
    const db = getDb();
    if (!request.auth) throw new HttpsError("unauthenticated", "Logg inn først.");
    const uid = request.auth.uid;
    const data = request.data || {};
    const messages = sanitizeMessages(data.messages);
    if (!messages.length) throw new HttpsError("invalid-argument", "Ingen gyldig melding.");
    const lang = data.lang === "en" ? "en" : "no";
    const context = typeof data.context === "string" ? data.context.slice(0, MAX_CONTEXT_CHARS) : "";

    const plan = await getPlan(db, uid);
    const q = await takeQuota(db, uid, plan, now());
    if (!q.ok) {
      throw new HttpsError("resource-exhausted",
        lang === "en"
          ? `Daily limit reached (${q.limit} questions/day on your plan). Try again tomorrow.`
          : `Daglig grense nådd (${q.limit} spørsmål per dag på ditt abonnement). Prøv igjen i morgen.`);
    }

    const system = buildSystem({ lang, context, today: osloDate(now()) });
    const apiKey = process.env.ANTHROPIC_API_KEY;
    const searchOn = process.env.FLYING_AGENT_WEB_SEARCH !== "off";
    try {
      let content;
      try {
        content = await callAnthropic(fetchFn, apiKey, system, messages, searchOn);
      } catch (e) {
        // Nettsøk-verktøyet kan være avslått på kontoen: prøv uten
        if (searchOn && e.status === 400 && /web_search|tool/i.test(e.body || "")) {
          console.warn("[flyingAgent] nettsøk avvist, prøver uten");
          content = await callAnthropic(fetchFn, apiKey, system, messages, false);
        } else {
          throw e;
        }
      }
      const out = extractText(content);
      if (!out.text) throw new Error("Tomt svar");
      return { content: formatReply(out), remaining: q.limit - q.used };
    } catch (e) {
      console.error("[flyingAgent] feil", e && e.message);
      await refundQuota(db, q.ref);
      throw new HttpsError("internal", "Flying Agent feilet. Prøv igjen om litt.");
    }
  };
}

exports.flyingAgent = onCall(
  { secrets: ["ANTHROPIC_API_KEY"], timeoutSeconds: 120, memory: "512MiB" },
  makeHandler({ getDb: () => admin.firestore(), fetchFn: (...a) => require("node-fetch")(...a) })
);

exports._internal = { makeHandler, sanitizeMessages, buildSystem, extractText, formatReply, osloDate, takeQuota, DAILY_LIMITS };
