#!/bin/bash
set -e
TARGET="scripts/build-email-html.mjs"
echo "📦 Bytter til versjonsløs logo-URL ..."

[ -f "$TARGET" ] || { echo "❌ Fant ikke $TARGET"; exit 1; }
cp "$TARGET" "$TARGET.bak_url_$(date +%Y%m%d_%H%M%S)"

# Bytt evt. versjonert URL -> versjonsløs (henter alltid nyeste)
sed -i.tmp -E 's#res\.cloudinary\.com/ds3xrvivm/image/upload/v[0-9]+/wa3jjnrx6k6skq01sqxg\.jpg#res.cloudinary.com/ds3xrvivm/image/upload/wa3jjnrx6k6skq01sqxg.jpg#g' "$TARGET"
rm -f "$TARGET.tmp"

echo "Logo-URL i fil:"
grep -o 'res.cloudinary.com/ds3xrvivm/image/upload[^"]*' "$TARGET" | head -1

echo ""
echo "🧪 Bygger forhåndsvisning med ny logo ..."
node scripts/build-email-html.mjs
echo "✅ Ferdig"
