#!/usr/bin/env bash
# 32 – favCapStored: hopp over enheter uten uid (lagret før innlogging ble påkrevd),
# slik at betalende brukere ikke nedgraderes til free i minnet. Kjør: bash scripts/32_fav_cap_skip_legacy.sh
set -euo pipefail
cd "$(dirname "$0")/.."
F="api/server.js"
[ -f "$F" ] || { echo "❌ Fant ikke $F – kjør fra repo-roten"; exit 1; }
if grep -q "\[32\] skip-legacy" "$F"; then echo "ℹ️  Allerede patchet"; exit 0; fi
grep -q "async function favCapStored(favs) {" "$F" || { echo "❌ Fant ikke favCapStored"; exit 1; }
cp "$F" "$F.bak32"
node - "$F" <<'JS'
const fs = require('fs');
const f = process.argv[2];
let s = fs.readFileSync(f, 'utf8');
const a = 'async function favCapStored(favs) {\n';
if (s.split(a).length !== 2) { console.error('❌ uventet antall treff'); process.exit(2); }
s = s.replace(a, a + "  if (!favs || !favs.uid) return; // [32] skip-legacy: ingen uid = lagret før innlogging, ikke nedgrader\n");
fs.writeFileSync(f, s);
JS
if ! node --check "$F"; then cp "$F.bak32" "$F"; echo "❌ Syntaksfeil – rullet tilbake"; exit 1; fi
echo "✅ Patchet $F (backup: $F.bak32)"
echo "Neste: git add api/server.js scripts/32_fav_cap_skip_legacy.sh && git commit -m 'Ikke nedgrader enheter uten uid' && git push"
