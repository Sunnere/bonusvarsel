#!/usr/bin/env bash
# Skript 27: Trippel Trumf-varsel søndag 15:00 (4 dager før) og onsdag 18:00 (1 dag før).
# Datoer styres per torsdag i TRIPPEL_TRUMF_SLOTS_2026. 15. okt beholder gammel tirsdag-18:00-regel.
set -euo pipefail
cd "$(dirname "$0")/.."
FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Finner ikke $FILE (kjør fra repo-roten)"; exit 1; }
if grep -q "trippelTrumfWindow" "$FILE"; then
  echo "⚠️  Skriptet er allerede kjørt (trippelTrumfWindow finnes). Avbryter."; exit 1
fi
mkdir -p .script_backups
BK=".script_backups/server.js.$(date +%Y%m%d_%H%M%S).bak"
cp "$FILE" "$BK" && echo "💾 Backup: $BK"

python3 - "$FILE" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()

NEW_BLOCK = r'''const TRIPPEL_TRUMF_SLOTS_2026 = {
  '2026-10-15': [{ daysBefore: 2, hour: 18 }],
  '2026-11-12': [{ daysBefore: 4, hour: 15 }, { daysBefore: 1, hour: 18 }],
};
const TT_MONTHS_NO = ['januar','februar','mars','april','mai','juni','juli','august','september','oktober','november','desember'];
const TT_WEEKDAYS_NO = ['søndag','mandag','tirsdag','onsdag','torsdag','fredag','lørdag'];
function trippelTrumfDateOffset(days) {
  const now = osloNow();
  const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + days);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
function trippelTrumfNorskDato(iso) {
  const [y, m, d] = iso.split('-').map(Number);
  const wd = TT_WEEKDAYS_NO[new Date(y, m - 1, d).getDay()];
  return `${wd} ${d}. ${TT_MONTHS_NO[m - 1]}`;
}
// Returnerer varselinfo hvis nå er et varselvindu for Trippel Trumf, ellers null
function trippelTrumfWindow() {
  const now = osloNow();
  for (const [target, slots] of Object.entries(TRIPPEL_TRUMF_SLOTS_2026)) {
    for (const s of slots) {
      if (now.getHours() !== s.hour) continue;
      if (trippelTrumfDateOffset(s.daysBefore) !== target) continue;
      return {
        dateKey: target,
        daysBefore: s.daysBefore,
        when: s.daysBefore === 1 ? 'i morgen' : trippelTrumfNorskDato(target),
      };
    }
  }
  return null;
}

'''

start = s.find("function trippelTrumfDateTomorrow() {")
end = s.find("function pickWeeklyGeneralOffers(")
if start < 0 or end < 0 or s.count("function trippelTrumfDateTomorrow() {") != 1 or s.count("function pickWeeklyGeneralOffers(") != 1 or end < start:
    print("❌ Fant ikke entydig blokk for trippelTrumf-funksjonene"); sys.exit(1)
s = s[:start] + NEW_BLOCK + s[end:]

old_call = """      if (isTrippelTrumfEveWindow()) {
        const dateKey = trippelTrumfDateTomorrow();
        const ttKey = `${deviceId}-trippeltrumf-${dateKey}`;"""
new_call = """      const ttW = trippelTrumfWindow();
      if (ttW) {
        const { dateKey, daysBefore, when } = ttW;
        const ttKey = daysBefore === 2
          ? `${deviceId}-trippeltrumf-${dateKey}`
          : `${deviceId}-trippeltrumf-${dateKey}-d${daysBefore}`;"""

reps = [
  (old_call, new_call),
  ("<b>Trippel Trumf er trolig i morgen!</b>", "<b>Trippel Trumf er trolig ${when}!</b>"),
  ('<h2 style="color:#0F2340;">🔔 Trippel Trumf er trolig i morgen!</h2>', '<h2 style="color:#0F2340;">🔔 Trippel Trumf er trolig ${when}!</h2>'),
  ("'🔔 Trippel Trumf er trolig i morgen!'", "`🔔 Trippel Trumf er trolig ${when}!`"),
]
for o, n in reps:
    c = s.count(o)
    if c != 1:
        print(f"❌ Fant {c} treff (forventet 1) for:\n{o[:90]}"); sys.exit(1)
    s = s.replace(o, n)

open(p, 'w', encoding='utf-8').write(s)
print("✅ Patchet", p)
PY

node --check "$FILE" && echo "✅ node --check OK"
echo "➡️  Neste: commit og push, deretter test i produksjon."
