#!/bin/bash
set -euo pipefail

FILE="api/server.js"
BACKUP="${FILE}.bak_1019_enforce_tier_limits_$(date +%Y%m%d_%H%M%S)"

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

old = '''app.post("/v1/devices/favorites", express.json(), (req, res) => {
  const { trumf = [], sas = [], email = null, telegram = null, tier = 'free' } = req.body || {};
  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf, sas, email, telegram, tier, updatedAt: new Date().toISOString() };
  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumf.length}, SAS=${sas.length}, Email=${email || 'ingen'}, Telegram=${telegram || 'ingen'}, Tier=${tier}`);
  res.json({ ok: true, trumf: trumf.length, sas: sas.length });
});'''

new = '''const TIER_FAVORITE_LIMITS = { free: 0, premium: 5, elite: 10 };

app.post("/v1/devices/favorites", express.json(), (req, res) => {
  const { trumf = [], sas = [], email = null, telegram = null, tier: rawTier = 'free' } = req.body || {};
  const tier = Object.prototype.hasOwnProperty.call(TIER_FAVORITE_LIMITS, rawTier) ? rawTier : 'free';
  const limit = TIER_FAVORITE_LIMITS[tier];

  const trumfCapped = Array.isArray(trumf) ? trumf.slice(0, limit) : [];
  const sasCapped = Array.isArray(sas) ? sas.slice(0, limit) : [];

  const deviceId = req.headers['x-device-id'] || 'default';
  deviceFavorites[deviceId] = { trumf: trumfCapped, sas: sasCapped, email, telegram, tier, updatedAt: new Date().toISOString() };

  const wasTruncated = trumfCapped.length !== trumf.length || sasCapped.length !== sas.length || tier !== rawTier;
  if (wasTruncated) {
    console.warn(`[v1/devices/favorites] ${deviceId}: begrenset til tier-grense (tier=${tier}, limit=${limit}, forsøkte Trumf=${trumf.length} SAS=${sas.length})`);
  }

  console.log(`Favoritter oppdatert for ${deviceId}: Trumf=${trumfCapped.length}, SAS=${sasCapped.length}, Email=${email || 'ingen'}, Telegram=${telegram || 'ingen'}, Tier=${tier}`);
  res.json({ ok: true, trumf: trumfCapped.length, sas: sasCapped.length, tier, limit });
});'''

if old not in src:
    print("❌ Fant ikke forventet blokk. Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ Server-side håndheving av tier-grenser lagt til")
PYEOF

echo "✅ Backup laget: $BACKUP"
echo "Verifiser: node --check $FILE"
