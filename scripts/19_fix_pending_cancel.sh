#!/usr/bin/env bash
# 19_fix_pending_cancel.sh
# Fjerner tilgang for kjop gjort for konto fantes, nar Stripe-abonnementet avsluttes.
# Bruk: bash scripts/19_fix_pending_cancel.sh [rot-mappe]   (default: ~/bonusvarsel)
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/functions/index.js"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }

if grep -q "PENDING_CANCEL_FIX_V1" "$FILE"; then
  echo "OK: allerede patchet. Ingenting a gjore."
  exit 0
fi

cp "$FILE" "$FILE.bak_19"

python3 - "$FILE" <<'PY'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
anchor = '  res.status(200).send("OK");\n});\n\n// ── Sjekk abonnement'
n = src.count(anchor)
if n != 1:
    sys.exit(f"FEIL: fant {n} forekomster av ankeret (forventet 1). Ingen endringer gjort.")
block = '''  // PENDING_CANCEL_FIX_V1: fjern tilgang for kjop gjort for konto fantes, nar Stripe-abonnementet avsluttes
  if (event.type === "customer.subscription.deleted") {
    try {
      const customerId = event.data.object.customer;
      if (customerId) {
        const pendSnap = await db.collection("pending_subscriptions")
          .where("stripeCustomerId", "==", customerId).get();
        for (const d of pendSnap.docs) {
          await d.ref.set({
            plan: "free",
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          console.log(`Pending-tilgang fjernet for ${d.id} (customer ${customerId})`);
        }
      }
    } catch (err) {
      console.error("Feil ved pending-kansellering:", err);
    }
  }

'''
new = src.replace(anchor, block + anchor, 1)
open(path, "w", encoding="utf-8").write(new)
print("Patch satt inn")
PY

if command -v node >/dev/null 2>&1; then
  if ! node --check "$FILE" 2>/dev/null; then
    echo "FEIL: syntaksfeil etter patch. Gjenoppretter original."
    mv "$FILE.bak_19" "$FILE"
    exit 1
  fi
  echo "Syntaks OK"
fi

rm -f "$FILE.bak_19"
echo "OK: $FILE er patchet. Test for du deployer."
