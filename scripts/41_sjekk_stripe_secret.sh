#!/bin/bash
# 41_sjekk_stripe_secret.sh – viser hvilken STRIPE_WEBHOOK_SECRET stripeWebhook bruker (bare utdrag)
P=bonusvarsel
S=STRIPE_WEBHOOK_SECRET
echo "== 1. Versjoner i Secret Manager (nyeste øverst)"
gcloud secrets versions list "$S" --project "$P" --limit=5 --format="table(name,state,createTime)"
echo
echo "== 2. Versjon som stripewebhook er bundet til"
gcloud run services describe stripewebhook --region us-central1 --project "$P" --format=yaml | grep -A6 "name: $S" | grep -E "key:|name:" | head -4
echo
echo "== 3. Innhold i nyeste versjon (trygt utdrag)"
V=$(gcloud secrets versions access latest --secret "$S" --project "$P")
RAW=$(gcloud secrets versions access latest --secret "$S" --project "$P" | wc -c | tr -d ' ')
echo "Starter med : ${V:0:12}..."
echo "Lengde      : $RAW tegn (uten linjeskift: ${#V})"
[ "$RAW" != "${#V}" ] && echo "ADVARSEL: linjeskift på slutten - legg inn på nytt med echo -n"
echo
echo "Sammenlign 'Starter med' med Signing secret (Reveal) på endpointet"
echo "«Aktiverer Premium/Elite etter betaling» i Stripe."
