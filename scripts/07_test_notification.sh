#!/bin/bash
# Sender en testmelding til din e-post og Telegram med en gang

EMAIL="royrotvold@gmail.com"
TELEGRAM="@dittbrukernavn"   # ← bytt til ditt Telegram-brukernavn

PROJECT="bonusvarsel"

echo "📨 Sender testmelding..."

curl -X POST \
  "https://sendweeklyoffernotification-2h6asrpfoq-uc.a.run.app" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"email\": \"$EMAIL\",
      \"telegram\": \"$TELEGRAM\",
      \"message\": \"🔔 *Test fra Bonusvarsel*\n\n🟢 *Trumf Netthandel*\n• Outnorth – 50 p/100kr\n• Gina Tricot – 60 p/100kr\n👉 https://trumfnetthandel.no\n\n✈️ *SAS Online Shopping*\n• Booking.com – 15 p/100kr\n• Scandic Hotels – 20 p/100kr\n👉 https://onlineshopping.flysas.com/nb-NO\",
      \"sasCount\": 2,
      \"trumfCount\": 2
    }
  }"

echo ""
echo "✅ Ferdig – sjekk e-post og Telegram!"
