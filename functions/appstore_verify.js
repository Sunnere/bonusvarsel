// Verifiserer App Store-kjøp server-side (App Store Server API) og skriver plan til subscriptions/{uid},
// slik at App Store-kunder behandles likt som Stripe- og Google Play-kunder.
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { Timestamp } = require("firebase-admin/firestore");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const KEY_ID = "ZQF632P8J4";
const BUNDLE_ID = "com.royrotvold.bonusvarsel";
const PLAN_RANK = { free: 0, premium: 1, pro: 1, elite: 2 };
const PROD = "https://api.storekit.itunes.apple.com";
const SANDBOX = "https://api.storekit-sandbox.itunes.apple.com";

const b64u = (b) => Buffer.from(b).toString("base64url");

function makeJwt({ keyId, issuerId, bundleId, privateKey, nowMs = Date.now() }) {
  const iat = Math.floor(nowMs / 1000);
  const head = b64u(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }));
  const body = b64u(JSON.stringify({ iss: issuerId, iat, exp: iat + 1200, aud: "appstoreconnect-v1", bid: bundleId }));
  const sig = crypto.sign("sha256", Buffer.from(`${head}.${body}`), { key: privateKey, dsaEncoding: "ieee-p1363" });
  return `${head}.${body}.${b64u(sig)}`;
}

function decodeJws(jws) {
  const p = String(jws).split(".");
  if (p.length !== 3) return null;
  try { return JSON.parse(Buffer.from(p[1], "base64url").toString("utf8")); } catch (e) { return null; }
}

function planFromProduct(id) {
  const s = String(id || "");
  if (s.includes("elite")) return "elite";
  if (s.includes("premium")) return "premium";
  return null;
}

// Henter transaksjonshistorikk: først produksjon, så sandbox (TestFlight/utviklerbygg).
async function fetchHistory(fetchFn, jwt, txnId) {
  for (const base of [PROD, SANDBOX]) {
    const all = [];
    let revision = null;
    let notFound = false;
    for (let page = 0; page < 5; page++) {
      const url = `${base}/inApps/v1/history/${encodeURIComponent(txnId)}?sort=DESCENDING` +
        (revision ? `&revision=${encodeURIComponent(revision)}` : "");
      const r = await fetchFn(url, { headers: { Authorization: `Bearer ${jwt}` } });
      if (r.status === 404 || r.status === 400) { if (page === 0) notFound = true; break; }
      if (r.status === 401 || r.status === 403) throw Object.assign(new Error("Apple auth " + r.status), { appleAuth: true });
      if (!r.ok) throw new Error("Apple " + r.status);
      const j = await r.json();
      all.push(...(j.signedTransactions || []).map(decodeJws).filter(Boolean));
      if (!j.hasMore) break;
      revision = j.revision;
    }
    if (!notFound) return all;
  }
  return null;
}

function makeHandler({ getDb, fetchFn, getKey, getIssuerId, now = () => Date.now() }) {
  return async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Må være innlogget.");
    const uid = request.auth.uid;
    const txnId = request.data ? request.data.transactionId : null;
    if (typeof txnId !== "string" || !/^[0-9]{5,25}$/.test(txnId)) {
      throw new HttpsError("invalid-argument", "Ugyldig transaksjons-ID.");
    }
    const issuerId = getIssuerId();
    if (!issuerId) {
      console.error("[verifyAppStorePurchase] APPLE_ISSUER_ID mangler");
      throw new HttpsError("failed-precondition", "Serveren mangler Apple-oppsett.");
    }
    const db = getDb();

    let txns;
    try {
      const jwt = makeJwt({ keyId: KEY_ID, issuerId, bundleId: BUNDLE_ID, privateKey: getKey(), nowMs: now() });
      txns = await fetchHistory(fetchFn, jwt, txnId);
    } catch (e) {
      console.error("[verifyAppStorePurchase] feil mot Apple", e && e.message);
      throw new HttpsError("internal", e && e.appleAuth ? "Apple-autentisering feilet." : "Kunne ikke kontakte Apple. Prøv igjen.");
    }
    const mine = (txns || []).filter((t) => t.bundleId === BUNDLE_ID && planFromProduct(t.productId));
    if (!mine.length) return { active: false, plan: "free" };

    mine.sort((a, b) => (b.expiresDate || 0) - (a.expiresDate || 0));
    const latest = mine[0];
    const plan = planFromProduct(latest.productId);
    const origId = String(latest.originalTransactionId || txnId);
    const active = !!latest.expiresDate && latest.expiresDate > now() && !latest.revocationDate;

    // Ett kjøp kan bare kobles til én konto
    const bindRef = db.collection("appstore_purchases").doc(origId);
    const bindSnap = await bindRef.get();
    if (bindSnap.exists && bindSnap.data().uid !== uid) {
      console.error(`[verifyAppStorePurchase] ${origId} er koblet til annen uid. Forsøk fra ${uid}`);
      throw new HttpsError("already-exists", "Kjøpet er allerede koblet til en annen konto.");
    }

    const subRef = db.collection("subscriptions").doc(uid);
    const subSnap = await subRef.get();
    const existing = subSnap.exists ? subSnap.data() || {} : null;

    if (!active) {
      if (existing && existing.source === "app_store") {
        await subRef.set({ plan: "free", updatedAt: new Date(now()) }, { merge: true });
      }
      return { active: false, plan: "free" };
    }

    await bindRef.set({ uid, productId: latest.productId, updatedAt: new Date(now()) }, { merge: true });

    // Ikke overstyr en like høy eller høyere plan fra Stripe/Google Play
    if (existing && existing.source !== "app_store" && (PLAN_RANK[existing.plan] || 0) >= PLAN_RANK[plan]) {
      return { active: true, plan: existing.plan, kept: true };
    }
    await subRef.set({
      plan,
      source: "app_store",
      productId: latest.productId,
      originalTransactionId: origId,
      appStoreExpiryTime: Timestamp.fromMillis(latest.expiresDate),
      updatedAt: new Date(now()),
    }, { merge: true });
    return { active: true, plan, expiresAt: new Date(latest.expiresDate).toISOString() };
  };
}

exports.verifyAppStorePurchase = onCall(
  { timeoutSeconds: 60 },
  makeHandler({
    getDb: () => admin.firestore(),
    fetchFn: (...a) => require("node-fetch")(...a),
    getKey: () => fs.readFileSync(path.join(__dirname, "keys", "SubscriptionKey.p8"), "utf8"),
    getIssuerId: () => process.env.APPLE_ISSUER_ID || "",
  })
);

exports._internal = { makeHandler, makeJwt, decodeJws, planFromProduct };
