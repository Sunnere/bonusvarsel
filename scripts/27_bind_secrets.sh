#!/bin/bash
set -e
TARGET="functions/index.js"
[ -f "$TARGET" ] || { echo "❌ Fant ikke $TARGET"; exit 1; }
cp "$TARGET" "$TARGET.bak_secrets_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
f = "functions/index.js"
s = open(f).read()
changed = []
SECRETS = '"TELEGRAM_BOT_TOKEN", "EMAIL_USER", "EMAIL_PASS", "EMAIL_FROM", "RAILWAY_URL"'

if 'secrets: ["EMAIL_PASS"' in s or 'secrets: ["TELEGRAM_BOT_TOKEN", "EMAIL_USER"' in s:
    print("ℹ️  Secrets ser ut til å være bundet allerede")
else:
    # onCall – uten options
    a = "exports.sendWeeklyOfferNotification = onCall(async (request) => {"
    b = f"exports.sendWeeklyOfferNotification = onCall({{ secrets: [{SECRETS}] }}, async (request) => {{"
    if a in s:
        s = s.replace(a, b, 1); changed.append("onCall")
    # onCall – med eksisterende appcheck-options
    a2 = "exports.sendWeeklyOfferNotification = onCall({ enforceAppCheck: false, allowInvalidAppCheckToken: true }, async (request) => {"
    b2 = f"exports.sendWeeklyOfferNotification = onCall({{ enforceAppCheck: false, allowInvalidAppCheckToken: true, secrets: [{SECRETS}] }}, async (request) => {{"
    if a2 in s:
        s = s.replace(a2, b2, 1); changed.append("onCall(appcheck)")

    # onSchedule
    a3 = "exports.weeklyOffersScheduler = onSchedule({\n  schedule: '0 9 * * 1,3,5',\n  timeZone: 'Europe/Oslo',\n}, async () => {"
    b3 = f"exports.weeklyOffersScheduler = onSchedule({{\n  schedule: '0 9 * * 1,3,5',\n  timeZone: 'Europe/Oslo',\n  secrets: [{SECRETS}],\n}}, async () => {{"
    if a3 in s:
        s = s.replace(a3, b3, 1); changed.append("onSchedule")

    open(f,"w").write(s)

print("Endret:", ", ".join(changed) if changed else "⚠️ ingenting – lim inn linjene rundt onCall/onSchedule så justerer jeg")
PYTHON

echo ""
echo "🧪 Syntaks..."
node --check "$TARGET" && echo "✅ Gyldig" || { echo "❌ Feil – gjenoppretter"; cp "$TARGET".bak_secrets_* "$TARGET"; exit 1; }
echo ""
echo "Secrets-binding nå:"
grep -n "secrets:" "$TARGET"
