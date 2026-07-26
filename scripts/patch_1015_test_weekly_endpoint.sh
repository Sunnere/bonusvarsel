#!/bin/bash
set -euo pipefail

FILE="api/server.js"
BACKUP="${FILE}.bak_1015_test_weekly_endpoint_$(date +%Y%m%d_%H%M%S)"

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

old = '''app.post("/dev/check-favorites", async (req, res) => {
  await checkFavoritesAndNotify();
  res.json({ ok: true, devices: Object.keys(deviceFavorites).length });
});'''

new = '''app.post("/dev/check-favorites", async (req, res) => {
  await checkFavoritesAndNotify();
  res.json({ ok: true, devices: Object.keys(deviceFavorites).length });
});

app.post("/dev/test-weekly-fallback", express.json(), async (req, res) => {
  try {
    const deviceId = req.headers["x-device-id"] || "default";
    const favs = deviceFavorites[deviceId];
    if (!favs) {
      return res.status(404).json({ ok: false, error: "Ingen enhet med denne x-device-id er registrert" });
    }

    const campaigns = await fetchAllCampaigns("elite");
    const topGeneral = campaigns
      .filter((c) => c.slug && (c.multiplier ?? 1) > 1)
      .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
      .slice(0, 2);

    if (!topGeneral.length) {
      return res.json({ ok: true, sent: false, reason: "Ingen kampanjer funnet akkurat nå" });
    }

    const tgLines = topGeneral.map((c) => bvTelegramLine(c)).join("\\n");
    const msg = `🔔 <b>[TEST] ${topGeneral.length} tilbud du bør sjekke!</b>\\n\\n${tgLines}\\n\\n${BV_TG_REMINDER}\\n\\n<i>(Dette er en manuell test - den ekte ukentlige meldingen kommer fortsatt onsdag kl 18 som normalt.)</i>`;

    const tgChatId = telegramDeviceStore.get(deviceId) || (favs.telegram ? telegramLinkStore.get(favs.telegram) : null);
    const tgOk = tgChatId ? await sendTelegram(msg, tgChatId) : false;

    let emailOk = false;
    if (favs.email) {
      const htmlCards = topGeneral.map((c) => bvOfferCard(c)).join("");
      const htmlMsg = `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 [TEST] ${topGeneral.length} tilbud du bør sjekke!</h2>${htmlCards}${BV_EMAIL_REMINDER}<p style="color:#94A3B8;font-size:12px;">(Dette er en manuell test - den ekte ukentlige meldingen kommer fortsatt onsdag kl 18 som normalt.)</p></div>`;
      emailOk = await sendEmail(favs.email, "🔔 [TEST] Bonusvarsel – ukens tilbud", htmlMsg);
    }

    res.json({
      ok: true,
      sent: true,
      telegramSent: tgOk,
      emailSent: emailOk,
      campaigns: topGeneral.map((c) => ({ title: c.title, multiplier: c.multiplier, source: c.source })),
    });
  } catch (e) {
    console.error("[dev/test-weekly-fallback] feil:", e);
    res.status(500).json({ ok: false, error: String(e) });
  }
});'''

if old not in src:
    print("❌ Fant ikke forventet /dev/check-favorites-blokk. Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ Lagt til /dev/test-weekly-fallback")
PYEOF

echo "✅ Backup laget: $BACKUP"
echo "Verifiser: node --check $FILE"
