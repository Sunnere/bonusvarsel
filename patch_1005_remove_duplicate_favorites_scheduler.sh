#!/bin/bash
set -e

FILE="api/server.js"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE — kjør dette fra rota av repoet."
  exit 1
fi

if ! grep -q "startFavoritesScheduler" "$FILE"; then
  echo "❌ Fant ikke startFavoritesScheduler() — er patch_1002/1003 kjørt fra før?"
  exit 1
fi

cp "$FILE" "${FILE}.bak-$(date +%Y%m%d%H%M%S)"
echo "📦 Sikkerhetskopi lagret: ${FILE}.bak-*"

python3 << 'PYEOF'
FILE = "api/server.js"

with open(FILE, "r") as f:
    content = f.read()

old_block = '''  checkFavoritesAndNotify()
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

if old_block not in content:
    raise SystemExit("❌ Fant ikke duplikat-scheduler-blokken i startAutoPipeline() — filen kan avvike fra det som ble analysert. Ingen endringer gjort.")

new_block = '''  setInterval(async () => {
    try {
      const result = await evaluateLivePipelineTick();
      console.log("Auto pipeline tick:", result);
    } catch (e) {
      console.error("Auto pipeline tick failed:", e);
    }
  }, autoPipelineIntervalMs);
  // NB: checkFavoritesAndNotify() kjøres IKKE lenger herfra.
  // Den kjøres uavhengig av ENABLE_DEV_ROUTES via startFavoritesScheduler()
  // (se lenger ned i filen) - dette unngår duplikat-kjøring og sikrer at
  // favoritt-varsler går ut selv når ENABLE_DEV_ROUTES=false i produksjon.
}'''

content = content.replace(old_block, new_block, 1)

with open(FILE, "w") as f:
    f.write(content)

print("✅ Duplikat favoritt-scheduler fjernet fra startAutoPipeline()")
print("   evaluateLivePipelineTick()-scheduleren er urørt.")
print("   startFavoritesScheduler() (patch_1002/1003) er nå eneste kilde til checkFavoritesAndNotify()-kall på intervall.")
PYEOF

node --check "$FILE" && echo "✅ $FILE — syntaks gyldig"

echo ""
echo "Verifiser at checkFavoritesAndNotify() nå kun kalles på intervall ETT sted:"
grep -n "setInterval.*=>.*{" "$FILE" | head -20
echo ""
echo "Antall gjenværende referanser til checkFavoritesAndNotify:"
grep -c "checkFavoritesAndNotify" "$FILE"
