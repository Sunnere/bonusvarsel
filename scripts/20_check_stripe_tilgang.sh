#!/usr/bin/env bash
# 20_check_stripe_tilgang.sh
# Sjekker tilgangskjeden for Stripe-kjop:
#  1. at avmeldingspatchen er i functions/index.js
#  2. at Stripe-webhooken lytter pa de riktige hendelsene
#  3. siste customer.subscription.deleted-hendelser
# Trenger en BEGRENSET nokkel (rk_live_...) med Read pa Webhook Endpoints og Events.
# Bruk: bash scripts/20_check_stripe_tilgang.sh [rot-mappe]   (default: ~/bonusvarsel)
set -uo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/functions/index.js"
WEBHOOK_HOST="stripewebhook-2h6asrpfoq-uc.a.run.app"
REQUIRED="invoice.paid checkout.session.completed customer.subscription.deleted"

echo "== 1. Kode i functions/index.js"
if [ ! -f "$FILE" ]; then
  echo "   FEIL: finner ikke $FILE"
else
  if grep -q "PENDING_CANCEL_FIX_V1" "$FILE"; then echo "   OK: avmeldingspatch er med"; else echo "   FEIL: PENDING_CANCEL_FIX_V1 mangler"; fi
  n=$(grep -c 'customer.subscription.deleted' "$FILE" || true)
  echo "   info: customer.subscription.deleted finnes $n gang(er) (forventet 2)"
  if grep -q 'pending_subscriptions' "$FILE" && grep -q 'stripeCustomerId: session.customer' "$FILE"; then
    echo "   OK: checkout lagrer stripeCustomerId i pending_subscriptions"
  else
    echo "   FEIL: fant ikke stripeCustomerId i pending-skrivingen"
  fi
fi

echo
echo "== 2 og 3. Stripe (krever begrenset nokkel)"
read -r -s -p "Lim inn rk_live_-nokkel (vises ikke): " SK; echo
if [ -z "$SK" ] || [[ "$SK" != rk_* && "$SK" != sk_* ]]; then
  echo "   Ingen gyldig nokkel gitt. Hopper over Stripe-sjekken."
  exit 0
fi

ENDPOINTS=$(curl -s https://api.stripe.com/v1/webhook_endpoints?limit=20 -u "$SK:")
EVENTS=$(curl -s "https://api.stripe.com/v1/events?type=customer.subscription.deleted&limit=5" -u "$SK:")
unset SK

echo "$ENDPOINTS" | python3 -c '
import sys, json
host, required = sys.argv[1], sys.argv[2].split()
d = json.load(sys.stdin)
if "error" in d:
    print("   FEIL fra Stripe:", d["error"].get("message", d["error"])); sys.exit(0)
eps = d.get("data", [])
match = [e for e in eps if host in e.get("url", "")]
if not match:
    print("   FEIL: fant ikke endepunkt med", host)
    for e in eps: print("   finnes:", e.get("url"), e.get("status"))
    sys.exit(0)
for e in match:
    enabled = set(e.get("enabled_events", []))
    print("   url:", e.get("url"), "| status:", e.get("status"))
    if "*" in enabled:
        print("   OK: lytter pa alle hendelser (*)")
    else:
        missing = [r for r in required if r not in enabled]
        print("   OK: alle paakrevde hendelser er med" if not missing else "   FEIL, mangler: " + ", ".join(missing))
others = [e.get("url") for e in eps if host not in e.get("url", "") and "bonusvarsel" in e.get("url", "")]
if others:
    print("   Merk: andre bonusvarsel-endepunkter (fjern dem hvis de skriver til userEntitlements):")
    for u in others: print("     -", u)
' "$WEBHOOK_HOST" "$REQUIRED"

echo "$EVENTS" | python3 -c '
import sys, json, datetime
d = json.load(sys.stdin)
if "error" in d:
    print("   FEIL fra Stripe:", d["error"].get("message", d["error"])); sys.exit(0)
evs = d.get("data", [])
if not evs:
    print("   Ingen customer.subscription.deleted-hendelser funnet.")
    print("   Si opp et testabonnement og kjor scriptet igjen.")
for e in evs:
    t = datetime.datetime.fromtimestamp(e["created"]).strftime("%d.%m.%Y %H:%M")
    cust = e["data"]["object"].get("customer")
    print(f"   {t}  event={e[chr(105)+chr(100)]}  customer={cust}")
print("   Sjekk status 200 under Developers > Webhooks > Recent events for disse.")
'

echo
echo "== Manuelt i Firebase Console (Firestore)"
echo "   Finn customer-ID fra listen over, og sjekk dokumentet:"
echo "   subscriptions/{uid}  eller  pending_subscriptions/{e-post}"
echo "   Forventet: plan = free, cancelledAt er satt."
