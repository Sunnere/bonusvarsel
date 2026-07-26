#!/bin/bash
set -euo pipefail

FILE="api/server.js"
BACKUP="${FILE}.bak_1017_trippel_trumf_reminder_$(date +%Y%m%d_%H%M%S)"

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

old_anchor = '''function pickWeeklyGeneralOffers(campaigns) {'''
new_anchor = '''const TRIPPEL_TRUMF_PREDICTED_DATES_2026 = [
  '2026-08-20',
  '2026-09-17',
  '2026-10-15',
  '2026-11-12',
  '2026-12-03',
];

function trippelTrumfDateTomorrow() {
  const now = osloNow();
  const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
  const yyyy = tomorrow.getFullYear();
  const mm = String(tomorrow.getMonth() + 1).padStart(2, '0');
  const dd = String(tomorrow.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function isTrippelTrumfEveWindow() {
  const now = osloNow();
  if (now.getHours() !== 18) return false;
  return TRIPPEL_TRUMF_PREDICTED_DATES_2026.includes(trippelTrumfDateTomorrow());
}

function pickWeeklyGeneralOffers(campaigns) {'''
edits.append((old_anchor, new_anchor))

old_loop = '''      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      const isFreeTier = !allFavSlugs.length;

      const newCampaigns = [];
      if (isFreeTier) {'''
new_loop = '''      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      const isFreeTier = !allFavSlugs.length;

      if (isTrippelTrumfEveWindow()) {
        const dateKey = trippelTrumfDateTomorrow();
        const ttKey = `${deviceId}-trippeltrumf-${dateKey}`;
        if (!sentKeysStore.has(ttKey)) {
          const tgChatIdTT = telegramDeviceStore.get(deviceId) || (favs.telegram ? telegramLinkStore.get(favs.telegram) : null);
          const ttMsg = `🔔 <b>Trippel Trumf er trolig i morgen!</b>\\n\\nHusk å skanne Trumf-kortet ditt i butikk (KIWI, MENY, SPAR, Joker m.fl.) for 3% bonus - 4% med Trumf Pay.\\n\\n<i>NB: Datoen er ikke offisielt bekreftet av Trumf ennå - sjekk Trumf-appen for siste nytt.</i>`;
          if (tgChatIdTT) await sendTelegram(ttMsg, tgChatIdTT);
          if (favs.email) {
            const ttHtml = `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 Trippel Trumf er trolig i morgen!</h2><p>Husk å skanne Trumf-kortet ditt i butikk (KIWI, MENY, SPAR, Joker m.fl.) for 3% bonus - 4% med Trumf Pay.</p><p style="color:#94A3B8;font-size:12px;">NB: Datoen er ikke offisielt bekreftet av Trumf ennå - sjekk Trumf-appen for siste nytt.</p></div>`;
            await sendEmail(favs.email, '🔔 Trippel Trumf er trolig i morgen!', ttHtml);
          }
          await sentKeysStore.add(ttKey);
        }
      }

      const newCampaigns = [];
      if (isFreeTier) {'''
edits.append((old_loop, new_loop))

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

print("✅ Trippel Trumf-påminnelse lagt til")
PYEOF

echo "✅ Backup laget: $BACKUP"
echo "Verifiser: node --check $FILE"
