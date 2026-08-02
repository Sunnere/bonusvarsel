#!/bin/bash
set -e

FILE="api/server.js"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE — kjør dette fra rota av repoet."
  exit 1
fi

if grep -q "startFavoritesScheduler" "$FILE"; then
  echo "⚠️  Scheduler finnes allerede i $FILE — avbryter for å unngå duplikat."
  exit 1
fi

cp "$FILE" "${FILE}.bak-$(date +%Y%m%d%H%M%S)"
echo "📦 Sikkerhetskopi lagret: ${FILE}.bak-*"

perl -0pi -e 's/(const monitorIntervalMs = Number\(process\.env\.MONITOR_INTERVAL_MS \|\| 30 \* 60 \* 1000\);\n)/$1let checkFavoritesIntervalMs = Number(process.env.CHECK_FAVORITES_INTERVAL_MS || 30 * 60 * 1000);\n/' "$FILE"

python3 << 'PYEOF'
import re

with open("api/server.js", "r") as f:
    content = f.read()

scheduler_block = '''// ── Favoritt-varsel scheduler (mail + Telegram) — kjører UANSETT ENABLE_DEV_ROUTES ──
// Rettet: checkFavoritesAndNotify() ble tidligere KUN trigget manuelt via
// /dev/check-favorites og kjørte aldri av seg selv - derfor uteble mail/Telegram.
function startFavoritesScheduler() {
  checkFavoritesAndNotify()
    .then(() => console.log("Favoritter-sjekk (initial) kjørt OK"))
    .catch((e) => console.error("Favoritter-sjekk (initial) feilet:", e));

  setInterval(async () => {
    try {
      await checkFavoritesAndNotify();
      console.log("Favoritter-sjekk (scheduler) kjørt OK");
    } catch (e) {
      console.error("Favoritter-sjekk (scheduler) feilet:", e);
    }
  }, checkFavoritesIntervalMs);

  console.log(`Favoritt-scheduler startet, intervall=${checkFavoritesIntervalMs}ms`);
}

// Vent til lagrene (Firestore-backed) er varmet opp før første kjøring,
// slik at dedup-nøkler er lastet inn og vi ikke sender duplikater ved oppstart.
setTimeout(() => startFavoritesScheduler(), 10000);

'''

anchor = "app.listen(port, () => {"
if anchor not in content:
    raise SystemExit("❌ Fant ikke anker-teksten 'app.listen(port, () => {' i filen")

content = content.replace(anchor, scheduler_block + anchor, 1)

with open("api/server.js", "w") as f:
    f.write(content)

print("✅ Python-innsetting OK")
PYEOF

node --check "$FILE" && echo "✅ $FILE — syntaks gyldig, scheduler lagt til"

echo ""
echo "Sjekk manuelt at disse linjene finnes i $FILE:"
grep -n "checkFavoritesIntervalMs\|startFavoritesScheduler\|intervall=" "$FILE"
