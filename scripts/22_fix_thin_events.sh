#!/usr/bin/env bash
# 22_fix_thin_events.sh
# Tilpasser stripeWebhook til Thin-hendelser fra Stripe:
#  - hopper over v2.-hendelser (Account Person osv.) med 200 OK
#  - henter full hendelse fra Stripe API nar data.object mangler
#  - gir STRIPE_EVENTS_KEY til funksjonen (ny hemmelighet)
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/functions/index.js"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }
if grep -q "THIN_FETCH_FIX_V1" "$FILE"; then echo "OK: allerede patchet."; exit 0; fi

cp "$FILE" "$FILE.bak_22"

python3 - "$FILE" <<'PY'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()

secrets_old = '  { secrets: ["STRIPE_WEBHOOK_SECRET"] },'
secrets_new = '  { secrets: ["STRIPE_WEBHOOK_SECRET", "STRIPE_EVENTS_KEY"] },'
parse_old = '    event = JSON.parse(payload);'
parse_new = '''    event = JSON.parse(payload);

    // THIN_FETCH_FIX_V1: v2-hendelser (Account Person osv.) ignoreres. Thin-hendelser
    // mangler data.object, derfor hentes hele hendelsen fra Stripe.
    if (String(event.type || "").startsWith("v2.")) {
      return res.status(200).send("OK");
    }
    if (!event.data || !event.data.object) {
      const r = await fetch(`https://api.stripe.com/v1/events/${event.id}`, {
        headers: { Authorization: `Bearer ${process.env.STRIPE_EVENTS_KEY}` },
      });
      if (!r.ok) {
        console.error("Kunne ikke hente hendelse fra Stripe:", r.status);
        return res.status(500).send("Kunne ikke hente hendelse");
      }
      event = await r.json();
    }'''

for name, a in [("secrets", secrets_old), ("parse", parse_old)]:
    n = src.count(a)
    if n != 1:
        sys.exit(f"FEIL: fant {n} forekomster for {name}. Ingen endringer gjort.")
src = src.replace(secrets_old, secrets_new, 1).replace(parse_old, parse_new, 1)
open(path, "w", encoding="utf-8").write(src)
print("Patch satt inn")
PY

if command -v node >/dev/null 2>&1 && ! node --check "$FILE" 2>/dev/null; then
  echo "FEIL: syntaksfeil. Gjenoppretter original."
  mv "$FILE.bak_22" "$FILE"
  exit 1
fi
rm -f "$FILE.bak_22"
echo "OK: $FILE er patchet."
echo "Neste: firebase functions:secrets:set STRIPE_EVENTS_KEY (begrenset nokkel, Read pa Events)"
