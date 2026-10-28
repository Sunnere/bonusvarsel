#!/usr/bin/env bash
# 29: Lås GET /v1/devices/favorites bak x-admin-key (lekker e-post/Telegram ellers)
# Bruk: bash scripts/29_protect_devices_favorites.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FILE="api/server.js"
[ -f "$FILE" ] || { echo "❌ Finner ikke $FILE (kjør fra repo-rot)"; exit 1; }

if grep -q "\[29\] admin-key" "$FILE"; then
  echo "✅ Allerede patchet (script 29) – ingenting å gjøre"; exit 0
fi
grep -q "/v1/devices/favorites" "$FILE" || { echo "❌ Fant ikke ruten /v1/devices/favorites"; exit 1; }

cp "$FILE" "$FILE.bak29"
node - "$FILE" <<'NODE'
const fs = require('fs');
const f = process.argv[2];
let s = fs.readFileSync(f, 'utf8');
const re = /(app\.get\(\s*(["'])\/v1\/devices\/favorites\2\s*,\s*\(\s*req\s*,\s*res\s*\)\s*=>\s*\{)/;
if (!re.test(s)) { console.error('❌ Mønster ikke funnet'); process.exit(2); }
const guard = `
  const adminKey = process.env.BV_ADMIN_KEY; // [29] admin-key
  if (!adminKey || req.headers['x-admin-key'] !== adminKey) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }`;
s = s.replace(re, (m) => m + guard);
fs.writeFileSync(f, s);
NODE

if ! node --check "$FILE"; then
  echo "❌ Syntaksfeil – ruller tilbake"; cp "$FILE.bak29" "$FILE"; exit 3
fi
echo "✅ Patchet $FILE (backup: $FILE.bak29)"
if grep -rn "devices/favorites" lib 2>/dev/null | grep -v "^Binary" | head -5 | grep -q .; then
  echo "⚠️  Flutter-appen refererer til ruten – sjekk:"
  grep -rn "devices/favorites" lib | head -5
fi
echo "Neste: git add api/server.js scripts/29_protect_devices_favorites.sh && git commit -m 'Lås /v1/devices/favorites bak x-admin-key' && git push"
