#!/usr/bin/env bash
# 25_lock_favorites.sh
# Låser /v1/devices/favorites:
#  - krever Firebase-innlogging (Authorization: Bearer <idToken>)
#  - henter tier fra serveren (subscriptions/{uid}, pending_subscriptions/{e-post})
#  - grenser per kategori: gratis 1 i hver (trumf, sas, spenn), premium 5, elite 10
#  - kapper eksisterende favoritter ved utsending når tier er endret
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/api/server.js"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }
if grep -q "FAV_LOCK_V1" "$FILE"; then echo "OK: allerede lastet."; exit 0; fi

cp "$FILE" "$FILE.bak_25"

python3 - "$FILE" <<'PY'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()

imp_anchor = "import * as entitlementStore from './lib/entitlementStore.js';"
route_anchor = 'app.post("/v1/devices/favorites", express.json(), (req, res) => {'
send_anchor = "      const allFavSlugs = Object.keys(LOYALTY_PROGRAMS).flatMap((programKey) => favs[programKey] || []);"

for name, a in [("import", imp_anchor), ("route", route_anchor), ("send", send_anchor)]:
    n = src.count(a)
    if n != 1:
        sys.exit(f"FEIL: fant {n} forekomster for {name}-ankeret (forventet 1). Ingen endringer gjort.")

imports = imp_anchor + """
// FAV_LOCK_V1
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';"""

helpers = '''// FAV_LOCK_V1: favoritter krever innlogging, og grensene styres av serveren
const FAV_PROGRAM_KEYS = ['spenn', 'cashpoints'];
const FAV_LIMITS = {
  free:    { trumf: 1, sas: 1, spenn: 1, cashpoints: 0 },
  premium: { trumf: 5, sas: 5, spenn: 5, cashpoints: 5 },
  elite:   { trumf: 10, sas: 10, spenn: 10, cashpoints: 10 },
};

async function favRequireUser(req, res) {
  const h = String(req.headers.authorization || '');
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) {
    res.status(401).json({ ok: false, error: 'login_required' });
    return null;
  }
  try {
    const decoded = await getAuth().verifyIdToken(token);
    return { uid: decoded.uid, email: decoded.email ? String(decoded.email).toLowerCase() : null };
  } catch (e) {
    res.status(401).json({ ok: false, error: 'invalid_token' });
    return null;
  }
}

async function favResolveTier(uid, email) {
  try {
    const db = getFirestore();
    const paid = (p) => p === 'premium' || p === 'elite';
    if (uid) {
      const s = await db.collection('subscriptions').doc(uid).get();
      if (s.exists) {
        const d = s.data();
        const expired = d.source === 'google_play' && d.playExpiryTime && d.playExpiryTime.toMillis() < Date.now();
        if (!expired && paid(d.plan)) return d.plan;
      }
    }
    if (email) {
      const p = await db.collection('pending_subscriptions').doc(email.toLowerCase()).get();
      if (p.exists && paid(p.data().plan)) return p.data().plan;
    }
  } catch (e) {
    console.error('[favResolveTier] feil:', e.message);
  }
  return 'free';
}

function favCapArr(arr, n) {
  if (!Array.isArray(arr)) return [];
  return arr
    .filter((x) => typeof x === 'string')
    .filter((x, i, a) => a.indexOf(x) === i)
    .slice(0, n);
}

async function favCapStored(favs) {
  const tier = await favResolveTier(favs.uid || null, favs.email || null);
  const lim = FAV_LIMITS[tier];
  favs.tier = tier;
  favs.trumf = favCapArr(favs.trumf, lim.trumf);
  favs.sas = favCapArr(favs.sas, lim.sas);
  favs.programs = (Array.isArray(favs.programs) ? favs.programs : [])
    .filter((p) => FAV_PROGRAM_KEYS.includes(p) && lim[p] > 0)
    .filter((p, i, a) => a.indexOf(p) === i);
}

'''

route_new = '''app.post("/v1/devices/favorites", express.json(), async (req, res) => {
  const user = await favRequireUser(req, res);
  if (!user) return;
  const deviceId = String(req.headers['x-device-id'] || '').trim();
  if (!deviceId) return res.status(400).json({ ok: false, error: 'x-device-id mangler' });
  const existing = deviceFavorites[deviceId];
  if (existing && existing.uid && existing.uid !== user.uid) {
    return res.status(403).json({ ok: false, error: 'device_owned_by_other_user' });
  }
  const tier = await favResolveTier(user.uid, user.email);
  const lim = FAV_LIMITS[tier];
  const body = req.body || {};
  const programs = (Array.isArray(body.programs) ? body.programs : [])
    .filter((p) => FAV_PROGRAM_KEYS.includes(p) && lim[p] > 0)
    .filter((p, i, a) => a.indexOf(p) === i);
  const record = {
    uid: user.uid,
    email: user.email,
    telegram: typeof body.telegram === 'string' ? body.telegram : null,
    tier,
    trumf: favCapArr(body.trumf, lim.trumf),
    sas: favCapArr(body.sas, lim.sas),
    programs,
    updatedAt: new Date().toISOString(),
  };
  deviceFavorites[deviceId] = record;
  deviceFavoritesStore.persist(deviceId, record).catch((err) => {
    console.error(`[v1/devices/favorites] Persistering feilet for ${deviceId}:`, err.message);
  });
  res.json({ ok: true, tier, limits: lim });
});

'''
legacy = route_anchor.replace("/v1/devices/favorites", "/v1/devices/favorites_legacy_disabled")

new = src.replace(imp_anchor, imports, 1)
new = new.replace(route_anchor, helpers + route_new + legacy, 1)
new = new.replace(send_anchor, "      await favCapStored(favs);\n" + send_anchor, 1)
open(path, "w", encoding="utf-8").write(new)
print("Favoritter låst")
PY

cp "$FILE" /tmp/_check_server.mjs
if ! node --check /tmp/_check_server.mjs 2>/dev/null; then
  echo "FEIL: syntaksfeil. Gjenoppretter original."
  mv "$FILE.bak_25" "$FILE"
  rm -f /tmp/_check_server.mjs
  exit 1
fi
rm -f /tmp/_check_server.mjs "$FILE.bak_25"
echo "OK: $FILE er oppdatert. Appen må sende Firebase-token før favoritter kan lagres."
