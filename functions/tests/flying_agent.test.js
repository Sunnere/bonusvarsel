const assert = require("assert");
const path = require("path");
const { _internal } = require(path.join(__dirname, "../flying_agent.js"));
const { makeHandler, sanitizeMessages, extractText, formatReply, osloDate, buildSystem } = _internal;

// ── Fake Firestore ──
function fakeDb(initial = {}) {
  const store = { ...initial };
  const ref = (col, id) => ({ col, id, key: `${col}/${id}` });
  return {
    store,
    collection: (col) => ({ doc: (id) => ({ ...ref(col, id), get: async () => ({ exists: (`${col}/${id}`) in store, data: () => store[`${col}/${id}`] }) }) }),
    runTransaction: async (fn) => fn({
      get: async (r) => ({ exists: r.key in store, data: () => store[r.key] }),
      set: (r, d) => { store[r.key] = { ...(store[r.key] || {}), ...d }; },
    }),
  };
}
const okFetch = (content, calls = []) => async (url, opts) => { calls.push(JSON.parse(opts.body)); return { ok: true, json: async () => ({ content, stop_reason: "end_turn" }) }; };

(async () => {
  // sanitize
  const m = sanitizeMessages([{ role: "assistant", content: "hei" }, { role: "user", content: "a" }, { role: "user", content: "b" }, { role: "assistant", content: "❌ feil" }, { role: "user", content: "x".repeat(9000) }, { role: "system", content: "no" }]);
  assert.deepStrictEqual(m.map((x) => x.role), ["user"]);
  assert.ok(m[0].content.startsWith("a\n\nb\n\n") && m[0].content.length < 4000 + 10);

  // osloDate
  assert.strictEqual(osloDate(new Date("2026-10-13T22:30:00Z")), "2026-10-14");

  // extractText + citations
  const out = extractText([{ type: "text", text: "Svar", citations: [{ url: "https://flysas.com/a", title: "SAS" }, { url: "https://flysas.com/a", title: "dup" }] }, { type: "server_tool_use" }]);
  assert.strictEqual(out.text, "Svar"); assert.strictEqual(out.sources.length, 1);
  assert.ok(formatReply(out).includes("Kilder:"));

  // system prompt
  const sys = buildSystem({ lang: "no", context: "EuroBonus: 1000", today: "2026-10-13" });
  assert.ok(sys.includes("SkyTeam") && sys.includes("EuroBonus: 1000") && sys.includes("Svar på norsk"));

  // handler: unauth
  const calls = [];
  const db = fakeDb();
  const h = makeHandler({ getDb: () => db, fetchFn: okFetch([{ type: "text", text: "Hei fra agent" }], calls), now: () => new Date("2026-10-13T10:00:00Z") });
  await assert.rejects(h({ data: {} }), (e) => e.code === "unauthenticated");
  await assert.rejects(h({ auth: { uid: "u1" }, data: { messages: [] } }), (e) => e.code === "invalid-argument");

  // free-limit 3
  const req = { auth: { uid: "u1" }, data: { messages: [{ role: "user", content: "Oslo–Bangkok?" }], lang: "no", context: "x".repeat(2000) } };
  for (let i = 1; i <= 3; i++) { const r = await h(req); assert.strictEqual(r.content, "Hei fra agent"); assert.strictEqual(r.remaining, 3 - i); }
  await assert.rejects(h(req), (e) => e.code === "resource-exhausted" && /Daglig grense/.test(e.message));
  assert.ok(calls[0].tools[0].name === "web_search" && calls[0].system[0].cache_control);
  assert.ok(calls[0].system[0].text.length < 20000 + 800 + 5000);

  // premium plan gets 15
  db.store["subscriptions/u2"] = { plan: "premium" };
  const req2 = { auth: { uid: "u2" }, data: req.data };
  for (let i = 0; i < 15; i++) await h(req2);
  await assert.rejects(h(req2), (e) => e.code === "resource-exhausted");

  // new day resets
  const h2 = makeHandler({ getDb: () => db, fetchFn: okFetch([{ type: "text", text: "ny dag" }]), now: () => new Date("2026-10-14T10:00:00Z") });
  assert.strictEqual((await h2(req)).content, "ny dag");

  // API failure refunds quota
  const bad = makeHandler({ getDb: () => db, fetchFn: async () => ({ ok: false, status: 500, text: async () => "boom" }), now: () => new Date("2026-10-15T10:00:00Z") });
  await assert.rejects(bad(req), (e) => e.code === "internal");
  assert.strictEqual(db.store["flying_agent_usage/u1_2026-10-15"].count, 0);

  // web_search rejected -> retry without tools
  const seen = [];
  const f = async (url, opts) => { const b = JSON.parse(opts.body); seen.push(!!b.tools); if (b.tools) return { ok: false, status: 400, text: async () => "web_search tool not enabled" }; return { ok: true, json: async () => ({ content: [{ type: "text", text: "uten søk" }], stop_reason: "end_turn" }) }; };
  const h3 = makeHandler({ getDb: () => db, fetchFn: f, now: () => new Date("2026-10-16T10:00:00Z") });
  assert.strictEqual((await h3(req)).content, "uten søk"); assert.deepStrictEqual(seen, [true, false]);

  // pause_turn continuation
  let n = 0;
  const g = async () => { n++; return { ok: true, json: async () => (n === 1 ? { content: [{ type: "server_tool_use" }], stop_reason: "pause_turn" } : { content: [{ type: "text", text: "ferdig" }], stop_reason: "end_turn" }) }; };
  const h4 = makeHandler({ getDb: () => db, fetchFn: g, now: () => new Date("2026-10-17T10:00:00Z") });
  assert.strictEqual((await h4(req)).content, "ferdig"); assert.strictEqual(n, 2);

  console.log("ALLE TESTER OK");
})().catch((e) => { console.error("FEIL", e); process.exit(1); });
