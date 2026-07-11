#!/bin/bash
set -e
TARGET="scripts/build-email-html.mjs"
echo "📦 Legger Bonusvarsel-logo i e-post-header ..."

[ -f "$TARGET" ] || { echo "❌ Fant ikke $TARGET – kjør 23_email_3d_look.sh først"; exit 1; }
cp "$TARGET" "$TARGET.bak_logo_$(date +%Y%m%d_%H%M%S)"

python3 << 'PY'
f = "scripts/build-email-html.mjs"
s = open(f).read()

LOGO = "https://res.cloudinary.com/ds3xrvivm/image/upload/v1782561421/wa3jjnrx6k6skq01sqxg.jpg"

# 1) Legg til LOGO_URL-konstant (hvis ikke allerede der)
if "LOGO_URL" not in s:
    s = s.replace(
      'const SAS_BASE = "https://onlineshopping.flysas.com/nb-NO/butikk/";',
      'const SAS_BASE = "https://onlineshopping.flysas.com/nb-NO/butikk/";\nconst LOGO_URL = "%s";' % LOGO
    )

# 2) Bytt 🔔-emoji-tittel med logo-bilde + tekst
old = '<div style="color:${GOLD};font-size:28px;font-weight:800;letter-spacing:0.5px;text-shadow:0 2px 4px rgba(0,0,0,0.4)">🔔 Bonusvarsel</div>'
new = ('<img src="${LOGO_URL}" width="64" height="64" alt="Bonusvarsel" '
       'style="border-radius:16px;display:inline-block;vertical-align:middle;'
       'box-shadow:0 6px 16px rgba(0,0,0,0.45),inset 0 1px 0 rgba(255,255,255,0.2)">\n'
       '        <div style="color:${GOLD};font-size:28px;font-weight:800;letter-spacing:0.5px;'
       'text-shadow:0 2px 4px rgba(0,0,0,0.4);margin-top:10px">Bonusvarsel</div>')

if old in s:
    s = s.replace(old, new)
    print("✅ Emoji byttet med logo")
elif "LOGO_URL}" in s:
    print("ℹ️  Logo allerede på plass – hopper over")
else:
    print("⚠️  Fant ikke header-linjen – sjekk filen manuelt")

open(f,"w").write(s)
PY

echo ""
echo "🧪 Bygger forhåndsvisning ..."
node scripts/build-email-html.mjs
echo "✅ Ferdig"
