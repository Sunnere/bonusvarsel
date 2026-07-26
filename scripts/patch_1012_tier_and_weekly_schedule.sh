#!/bin/bash
set -euo pipefail

FILE="api/server.js"
BACKUP="${FILE}.bak_1012_tier_and_weekly_$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE. Kjør dette scriptet fra rot-mappen i repoet."
  exit 1
fi

cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

edits = []

old_post = '''app.post("/v1/devices/favorites", express.json(), (req, res) => {
  const { trumf = [], sas = [], email = null, telegram = null } = req.body || {};
  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf, sas, email, telegram, updatedAt: new Date().toISOString() };
  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumf.length}, SAS=${sas.length}, Email=${email || 'ingen'}, Telegram=${telegram || 'ingen'}`);
  res.json({ ok: true, trumf: trumf.length, sas: sas.length });
});'''

new_post = '''app.post("/v1/devices/favorites", express.json(), (req, res) => {
  const { trumf = [], sas = [], email = null, telegram = null, tier = 'free' } = req.body || {};
  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf, sas, email, telegram, tier, updatedAt: new Date().toISOString() };
  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumf.length}, SAS=${sas.length}, Email=${email || 'ingen'}, Telegram=${telegram || 'ingen'}, Tier=${tier}`);
  res.json({ ok: true, trumf: trumf.length, sas: sas.length });
});'''

edits.append((old_post, new_post))

old_anchor = "async function checkFavoritesAndNotify() {"
new_anchor = '''function osloNow() {
  return new Date(new Date().toLocaleString('en-US', { timeZone: 'Europe/Oslo' }));
}

function isWeeklyFallbackWindow() {
  const now = osloNow();
  return now.getDay() === 3 && now.getHours() === 18;
}

function weekKey() {
  const now = osloNow();
  const firstJan = new Date(now.getFullYear(), 0, 1);
  const week = Math.ceil((((now - firstJan) / 86400000) + firstJan.getDay() + 1) / 7);
  return `${now.getFullYear()}-W${week}`;
}

async function checkFavoritesAndNotify() {'''

edits.append((old_anchor, new_anchor))

old_fallback = '''      const newCampaigns = [];
      if (isFreeTier) {
        // Free-tier uten favoritter: send topp 3 generelle tilbud
        const topGeneral = campaigns
          .filter(c => c.slug && (c.multiplier ?? 1) > 1)
          .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
          .slice(0, 3);
        for (const campaign of topGeneral) {
          const key = `${deviceId}-${campaign.slug}-${campaign.multiplier}`;
          if (sentKeysStore.has(key)) continue;
          newCampaigns.push(campaign);
          await sentKeysStore.add(key);
        }
      } else {'''

new_fallback = '''      const newCampaigns = [];
      if (isFreeTier) {
        if (!isWeeklyFallbackWindow()) continue;
        const topGeneral = campaigns
          .filter(c => c.slug && (c.multiplier ?? 1) > 1)
          .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
          .slice(0, 2);
        for (const campaign of topGeneral) {
          const key = `${deviceId}-weekly-${weekKey()}-${campaign.slug}-${campaign.multiplier}`;
          if (sentKeysStore.has(key)) continue;
          newCampaigns.push(campaign);
          await sentKeysStore.add(key);
        }
      } else {'''

edits.append((old_fallback, new_fallback))

missing = []
for old, new in edits:
    if old not in src:
        missing.append(old[:80])
    else:
        src = src.replace(old, new, 1)

if missing:
    print("❌ Fant ikke følgende kodeblokk(er), ingen endringer lagret:")
    for m in missing:
        print("   -", m)
    sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ server.js oppdatert")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  node --check $FILE"
