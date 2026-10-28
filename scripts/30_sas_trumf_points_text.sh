#!/usr/bin/env bash
# 30: Ekte tall i varsler: SAS (fast sum vs. per 100 kr + sluttdato) og Trumf (prosent)
# Bruk: bash scripts/30_sas_trumf_points_text.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FILE="api/server.js"
[ -f "$FILE" ] || { echo "❌ Finner ikke $FILE (kjør fra repo-rot)"; exit 1; }
grep -q "function bvPointsText" "$FILE" || { echo "❌ Fant ikke bvPointsText"; exit 1; }
if grep -q "\[30\] points-text" "$FILE"; then echo "✅ Allerede patchet (script 30)"; exit 0; fi

cp "$FILE" "$FILE.bak30"
node - "$FILE" <<'NODE'
const fs = require('fs');
const f = process.argv[2];
let s = fs.readFileSync(f, 'utf8');
const re = /function bvPointsText\(c\) \{[\s\S]*?\n\}\n/;
if (!re.test(s)) { console.error('❌ Mønster ikke funnet'); process.exit(2); }
const fn = `function bvPointsText(c) { // [30] points-text
  const nok = (n) => String(n).replace(/\\B(?=(\\d{3})+(?!\\d))/g, ' ');
  if (c.source === 'trumf') {
    const m = Number(c.multiplier);
    return m > 0 ? 'opptil ' + String(m).replace('.', ',') + ' % Trumf-bonus nå' : 'ekstra Trumf-bonus nå';
  }
  if (c.source === 'sas') {
    const r = c.raw || {};
    const camp = Number(r.points_campaign);
    const ends = r.campaign_ends_date ? ' (til ' + String(r.campaign_ends_date).replace(/[^0-9.]/g, '') + ')' : '';
    if (camp > 0 && r.commission_type === 'fixed')    return nok(camp) + ' EuroBonus-poeng fast' + ends;
    if (camp > 0 && r.commission_type === 'variable') return nok(camp) + ' EuroBonus-poeng per 100 kr' + ends;
    return 'ekstra EuroBonus-poeng nå';
  }
  return 'kampanje nå';
}
`;
s = s.replace(re, () => fn);
fs.writeFileSync(f, s);
NODE

if ! node --check "$FILE"; then echo "❌ Syntaksfeil – ruller tilbake"; cp "$FILE.bak30" "$FILE"; exit 3; fi
echo "✅ Patchet $FILE (backup: $FILE.bak30)"
echo "Neste: git add api/server.js scripts/30_sas_trumf_points_text.sh && git commit -m 'Varsler: ekte poeng/prosent + sluttdato' && git push"
