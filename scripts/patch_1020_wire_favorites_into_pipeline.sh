#!/bin/bash
set -e

FILE="api/server.js"
BACKUP="${FILE}.bak_1020_wire_favorites_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"
echo "Backup laget: $BACKUP"

python3 << 'PYEOF'
import sys

path = "api/server.js"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

if "Favorites/weekly check initial tick" in content:
    print("Patch er allerede anvendt - hopper over. Ingen endring gjort.")
    sys.exit(0)

old = '''function startAutoPipeline() {
  if (!enableDevRoutes) return;

  evaluateLivePipelineTick()
    .then((result) => {
      console.log("Auto pipeline initial tick:", result);
    })
    .catch((e) => {
      console.error("Auto pipeline initial tick failed:", e);
    });

  setInterval(async () => {
    try {
      const result = await evaluateLivePipelineTick();
      console.log("Auto pipeline tick:", result);
    } catch (e) {
      console.error("Auto pipeline tick failed:", e);
    }
  }, autoPipelineIntervalMs);
}'''

new = '''function startAutoPipeline() {
  if (!enableDevRoutes) return;

  evaluateLivePipelineTick()
    .then((result) => {
      console.log("Auto pipeline initial tick:", result);
    })
    .catch((e) => {
      console.error("Auto pipeline initial tick failed:", e);
    });

  checkFavoritesAndNotify()
    .then(() => {
      console.log("Favorites/weekly check initial tick: ok");
    })
    .catch((e) => {
      console.error("Favorites/weekly check initial tick failed:", e);
    });

  setInterval(async () => {
    try {
      const result = await evaluateLivePipelineTick();
      console.log("Auto pipeline tick:", result);
    } catch (e) {
      console.error("Auto pipeline tick failed:", e);
    }
  }, autoPipelineIntervalMs);

  setInterval(async () => {
    try {
      await checkFavoritesAndNotify();
      console.log("Favorites/weekly check tick: ok");
    } catch (e) {
      console.error("Favorites/weekly check tick failed:", e);
    }
  }, autoPipelineIntervalMs);
}'''

count = content.count(old)
if count == 0:
    print("FEIL: Fant ikke forventet kodeblokk. Ingen endring gjort. Sjekk om server.js er endret siden dette scriptet ble laget.")
    sys.exit(1)
if count > 1:
    print(f"FEIL: Fant kodeblokken {count} ganger - forventet noyaktig 1. Ingen endring gjort.")
    sys.exit(1)

content = content.replace(old, new)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("PATCH OK: checkFavoritesAndNotify() koblet inn i startAutoPipeline()")
PYEOF

echo ""
echo "Ferdig. Sjekk diff med:"
echo "  diff \"$BACKUP\" \"$FILE\""
