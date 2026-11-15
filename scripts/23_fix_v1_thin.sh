#!/usr/bin/env bash
# 23_fix_v1_thin.sh
# Retter Thin-henting: v2-destinasjonen sender v1.* hendelser som peker til related_object.url
# (f.eks. /v1/checkout/sessions/cs_...). Vi henter det objektet direkte, ikke /v1/events/{id}.
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/functions/index.js"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }
if grep -q "THIN_RELATED_FIX_V1" "$FILE"; then echo "OK: allerede patchet."; exit 0; fi
grep -q "THIN_FETCH_FIX_V1" "$FILE" || { echo "FEIL: kjor 22_fix_thin_events.sh forst."; exit 1; }

cp "$FILE" "$FILE.bak_23"

python3 - "$FILE" <<'PY'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
start = '    if (!event.data || !event.data.object) {'
end = '      event = await r.json();\n    }'
if src.count(start) != 1 or src.count(end) != 1:
    sys.exit("FEIL: fant ikke de forventede ankrene. Ingen endringer gjort.")
s = src.index(start)
e = src.index(end) + len(end)
new = '''    // THIN_RELATED_FIX_V1: hent objektet hendelsen peker til (related_object.url) og bygg hendelsen selv
    if (!event.data || !event.data.object) {
      const relUrl = event.related_object && event.related_object.url;
      if (!relUrl) {
        return res.status(200).send("OK");
      }
      const r = await fetch(`https://api.stripe.com${relUrl}`, {
        headers: { Authorization: `Bearer ${process.env.STRIPE_EVENTS_KEY}` },
      });
      if (!r.ok) {
        console.error("Kunne ikke hente objekt fra Stripe:", r.status, relUrl);
        return res.status(500).send("Kunne ikke hente objekt");
      }
      const obj = await r.json();
      event = {
        id: event.id,
        type: String(event.type).replace(/^v1\\./, ""),
        data: { object: obj },
      };
    }'''
new_src = src[:s] + new + src[e:]
open(path, "w", encoding="utf-8").write(new_src)
print("Patch satt inn")
PY

if command -v node >/dev/null 2>&1 && ! node --check "$FILE" 2>/dev/null; then
  echo "FEIL: syntaksfeil. Gjenoppretter original."
  mv "$FILE.bak_23" "$FILE"
  exit 1
fi
rm -f "$FILE.bak_23"
echo "OK: $FILE er patchet. Deploy stripeWebhook og Resend hendelsen."
