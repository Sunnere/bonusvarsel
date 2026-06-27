#!/bin/bash
set -e

# ─── FYLL INN DISSE FØR DU KJØRER ─────────────────────────────
TELEGRAM_BOT_TOKEN="8285933054:AAHfCs2seV0GrPqD6VOgTFRxoT0OWHMTO3E"
EMAIL_USER="royrotvold@gmail.com"
EMAIL_PASS="quuu owcf wtnd dpbs"
EMAIL_FROM="noreply@bonusvarsel.no"
RAILWAY_URL="https://bonusvarsel-production.up.railway.app"
# ───────────────────────────────────────────────────────────────

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$EMAIL_PASS" ]; then
  echo "❌ Fyll inn TELEGRAM_BOT_TOKEN og EMAIL_PASS i scriptet først"
  exit 1
fi

echo "🔑 Setter Firebase secrets..."
echo "$TELEGRAM_BOT_TOKEN" | firebase functions:secrets:set TELEGRAM_BOT_TOKEN
echo "$EMAIL_USER"         | firebase functions:secrets:set EMAIL_USER
echo "$EMAIL_PASS"         | firebase functions:secrets:set EMAIL_PASS
echo "$EMAIL_FROM"         | firebase functions:secrets:set EMAIL_FROM
echo "$RAILWAY_URL"        | firebase functions:secrets:set RAILWAY_URL
echo "✅ Secrets satt"

echo ""
echo "🚀 Deployer Firebase Functions..."
firebase deploy --only functions

echo ""
echo "✅ Alt deployet!"
echo ""
echo "📋 Sjekk at disse to funksjonene vises i Firebase Console:"
echo "   → sendWeeklyOfferNotification"
echo "   → weeklyOffersScheduler (kjører man/ons/fre 09:00)"
echo ""
echo "📋 For å skaffe Telegram Bot Token:"
echo "   1. Gå til https://t.me/BotFather"
echo "   2. Skriv /newbot"
echo "   3. Kopier token inn i TELEGRAM_BOT_TOKEN over"
echo ""
echo "📋 For Google App Password:"
echo "   1. Gå til myaccount.google.com"
echo "   2. Security → 2-Step Verification → App passwords"
echo "   3. Velg 'Mail' og generer passord"
echo "   4. Kopier inn i EMAIL_PASS over"

