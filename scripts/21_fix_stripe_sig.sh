#!/usr/bin/env bash
# 21_fix_stripe_sig.sh
# Retter Stripe-signaturkontrollen i functions/index.js:
#  - sjekker alle v1-signaturer (Stripe sender flere under rotasjon av hemmelighet)
#  - tidstoleranse 5 minutter (hindrer gjenbruk av gamle hendelser)
#  - konstant-tid sammenligning
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/functions/index.js"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }
if grep -q "STRIPE_SIG_FIX_V1" "$FILE"; then echo "OK: allerede patchet."; exit 0; fi

cp "$FILE" "$FILE.bak_21"

python3 - "$FILE" <<'PY'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
start_marker = '    const hmac = crypto.createHmac("sha256", STRIPE_WEBHOOK_SECRET);'
end_marker = '    event = JSON.parse(payload);'
if src.count(start_marker) != 1 or src.count(end_marker) != 1:
    sys.exit("FEIL: fant ikke de forventede ankrene. Ingen endringer gjort.")
s = src.index(start_marker)
e = src.index(end_marker)
if e < s:
    sys.exit("FEIL: uventet rekkefolge. Ingen endringer gjort.")
new_block = '''    // STRIPE_SIG_FIX_V1: sjekk alle v1-signaturer, tidstoleranse 5 min, konstant-tid sammenligning
    const parts = sig.split(",").map((p) => p.split("="));
    const t = parts.find(([k]) => k === "t")?.[1];
    const v1s = parts.filter(([k]) => k === "v1").map(([, v]) => v);
    if (!t || v1s.length === 0) {
      return res.status(400).send("Mangler signatur");
    }
    if (Math.abs(Date.now() / 1000 - Number(t)) > 300) {
      return res.status(400).send("Signatur for gammel");
    }
    const expected = crypto.createHmac("sha256", STRIPE_WEBHOOK_SECRET)
      .update(`${t}.${payload}`).digest("hex");
    const ok = v1s.some((v) =>
      v.length === expected.length &&
      crypto.timingSafeEqual(Buffer.from(v), Buffer.from(expected)));
    if (!ok) {
      console.error("Stripe signatur feil");
      return res.status(400).send("Ugyldig signatur");
    }

'''
new = src[:s] + new_block + src[e:]
open(path, "w", encoding="utf-8").write(new)
print("Patch satt inn")
PY

if command -v node >/dev/null 2>&1 && ! node --check "$FILE" 2>/dev/null; then
  echo "FEIL: syntaksfeil. Gjenoppretter original."
  mv "$FILE.bak_21" "$FILE"
  exit 1
fi
rm -f "$FILE.bak_21"
echo "OK: $FILE er patchet. Deploy stripeWebhook og test med Ping."
