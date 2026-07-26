#!/bin/bash
set -euo pipefail

FILE="api/server.js"
BACKUP="${FILE}.bak_1018_test_trippel_trumf_$(date +%Y%m%d_%H%M%S)"

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

old = '''  } catch (e) {
    console.error("[dev/test-weekly-fallback] feil:", e);
    res.status(500).json({ ok: false, error: String(e) });
  }
});'''

new = '''  } catch (e) {
    console.error("[dev/test-weekly-fallback] feil:", e);
    res.status(500).json({ ok: false, error: String(e) });
  }
});

app.post("/dev/test-trippel-trumf", express.json(), async (req, res) => {
  try {
    const deviceId = req.headers["x-device-id"] || "default";
    const favs = deviceFavorites[deviceId];
    if (!favs) {
      return res.status(404).json({ ok: false, error: "Ingen enhet med denne x-device-id er registrert" });
    }

    const nextDate = TRIPPEL_TRUMF_PREDICTED_DATES_2026.find((d) => d >= trippelTrumfDateTomorrow()) || TRIPPEL_TRUMF_PREDICTED_DATES_2026[0];
    const ttMsg = `🔔 <b>[TEST] Trippel Trumf er trolig ${nextDate}!</b>\\n\\nHusk å skanne Trumf-kortet ditt i butikk (KIWI, MENY, SPAR, Joker m.fl.) for 3% bonus - 4% med Trumf Pay.\\n\\n<i>NB: Datoen er ikke offisielt bekreftet av Trumf ennå - sjekk Trumf-appen for siste nytt.\\n(Dette er en manuell test - den ekte varslingen skjer fortsatt automatisk kvelden før.)</i>`;

    const tgChatId = telegramDeviceStore.get(deviceId) || (favs.telegram ? telegramLinkStore.get(favs.telegram) : null);
    const tgOk = tgChatId ? await sendTelegram(ttMsg, tgChatId) : false;

    let emailOk = false;
    if (favs.email) {
      const ttHtml = `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 [TEST] Trippel Trumf er trolig ${nextDate}!</h2><p>Husk å skanne Trumf-kortet ditt i butikk (KIWI, MENY, SPAR, Joker m.fl.) for 3% bonus - 4% med Trumf Pay.</p><p style="color:#94A3B8;font-size:12px;">NB: Datoen er ikke offisielt bekreftet av Trumf ennå.<br>(Dette er en manuell test - den ekte varslingen skjer fortsatt automatisk kvelden før.)</p></div>`;
      emailOk = await sendEmail(favs.email, "🔔 [TEST] Trippel Trumf er trolig " + nextDate, ttHtml);
    }

    res.json({ ok: true, sent: true, telegramSent: tgOk, emailSent: emailOk, predictedDate: nextDate });
  } catch (e) {
    console.error("[dev/test-trippel-trumf] feil:", e);
    res.status(500).json({ ok: false, error: String(e) });
  }
});'''

if old not in src:
    print("❌ Fant ikke forventet anker-blokk. Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ Lagt til /dev/test-trippel-trumf")
PYEOF

echo "✅ Backup laget: $BACKUP"
echo "Verifiser: node --check $FILE"
