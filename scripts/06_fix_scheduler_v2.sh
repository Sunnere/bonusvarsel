#!/bin/bash
set -e
TARGET="functions/index.js"

cp "$TARGET" "$TARGET.bak_v2fix_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 - << 'PYTHON'
with open('functions/index.js', 'r') as f:
    content = f.read()

old_require = "const nodemailer = require('nodemailer');"
new_require = """const nodemailer = require('nodemailer');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall } = require('firebase-functions/v2/https');"""

old_callable = "exports.sendWeeklyOfferNotification = functions.https.onCall(async (data) => {"
new_callable = "exports.sendWeeklyOfferNotification = onCall(async (request) => {\n  const data = request.data;"

old_scheduler = """exports.weeklyOffersScheduler = functions.pubsub
  .schedule('0 9 * * 1,3,5')
  .timeZone('Europe/Oslo')
  .onRun(async () => {"""
new_scheduler = """exports.weeklyOffersScheduler = onSchedule({
  schedule: '0 9 * * 1,3,5',
  timeZone: 'Europe/Oslo',
}, async () => {"""

changed = 0
if old_require in content:
    content = content.replace(old_require, new_require)
    changed += 1
else:
    print('⚠️  require-blokk ikke funnet')

if old_callable in content:
    content = content.replace(old_callable, new_callable)
    changed += 1
else:
    print('⚠️  onCall ikke funnet')

if old_scheduler in content:
    content = content.replace(old_scheduler, new_scheduler)
    changed += 1
else:
    print('⚠️  scheduler ikke funnet')

with open('functions/index.js', 'w') as f:
    f.write(content)
print(f'✅ {changed}/3 fikset til v2 syntax')
PYTHON

echo ""
echo "✅ Verifiserer syntax..."
cd functions && node -e "require('./index.js')" 2>&1 && echo "✅ Ingen syntaksfeil!" || echo "❌ Fortsatt feil"
