#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SOURCE_ICON="$HOME/Downloads/bonusvarsel_master.png"
MASTER="assets/app_icons/app_icon_master.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo "==> patch_751_require_exact_bonusvarsel_master_then_apply"
echo "==> Forventer nøyaktig denne fila:"
echo "   $SOURCE_ICON"
echo

if [ ! -f "$SOURCE_ICON" ]; then
  echo "❌ Fant ikke riktig manuelt lagret fil."
  echo
  echo "Gjør dette først:"
  echo "1) Gå tilbake til riktig bilde i chat"
  echo "2) Lagre bildet som:"
  echo "   ~/Downloads/bonusvarsel_master.png"
  echo "3) Kjør scriptet igjen"
  exit 1
fi

echo "==> Åpner fila for manuell kontroll"
open "$SOURCE_ICON"

echo
echo "⚠️  Sjekk nå at bildet som åpnet er riktig."
echo "Hvis det er feil, trykk Ctrl+C og lagre riktig fil."
read -r -p "Trykk ENTER når du har bekreftet at bildet er riktig ... "

mkdir -p assets/app_icons
mkdir -p "$IOS_DIR"

echo "==> Kopierer eksakt master inn i prosjektet"
cp "$SOURCE_ICON" "$MASTER"

echo "==> Verifiserer"
file "$MASTER" || true
ls -lh "$MASTER" || true

python3 -m pip install --quiet pillow >/dev/null 2>&1 || true

echo "==> Genererer iOS ikoner fra eksakt master"
python3 <<'PY'
from PIL import Image
import os

src = "assets/app_icons/app_icon_master.png"
dst = "ios/Runner/Assets.xcassets/AppIcon.appiconset"

img = Image.open(src).convert("RGB")

sizes = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

for name, px in sizes.items():
    out = os.path.join(dst, name)
    img.resize((px, px), Image.Resampling.LANCZOS).save(
        out,
        format="PNG",
        optimize=False,
        compress_level=0
    )
    print("✅", name)
PY

echo "==> Skriver Contents.json"
cat > "$IOS_DIR/Contents.json" <<'JSON'
{
  "images" : [
    { "size" : "20x20", "idiom" : "iphone", "filename" : "Icon-App-20x20@2x.png", "scale" : "2x" },
    { "size" : "20x20", "idiom" : "iphone", "filename" : "Icon-App-20x20@3x.png", "scale" : "3x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@1x.png", "scale" : "1x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@2x.png", "scale" : "2x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@3x.png", "scale" : "3x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "Icon-App-40x40@2x.png", "scale" : "2x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "Icon-App-40x40@3x.png", "scale" : "3x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "Icon-App-60x60@2x.png", "scale" : "2x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "Icon-App-60x60@3x.png", "scale" : "3x" },

    { "size" : "20x20", "idiom" : "ipad", "filename" : "Icon-App-20x20@1x.png", "scale" : "1x" },
    { "size" : "20x20", "idiom" : "ipad", "filename" : "Icon-App-20x20@2x.png", "scale" : "2x" },
    { "size" : "29x29", "idiom" : "ipad", "filename" : "Icon-App-29x29@1x.png", "scale" : "1x" },
    { "size" : "29x29", "idiom" : "ipad", "filename" : "Icon-App-29x29@2x.png", "scale" : "2x" },
    { "size" : "40x40", "idiom" : "ipad", "filename" : "Icon-App-40x40@1x.png", "scale" : "1x" },
    { "size" : "40x40", "idiom" : "ipad", "filename" : "Icon-App-40x40@2x.png", "scale" : "2x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "Icon-App-76x76@1x.png", "scale" : "1x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "Icon-App-76x76@2x.png", "scale" : "2x" },
    { "size" : "83.5x83.5", "idiom" : "ipad", "filename" : "Icon-App-83.5x83.5@2x.png", "scale" : "2x" },

    { "size" : "1024x1024", "idiom" : "ios-marketing", "filename" : "Icon-App-1024x1024@1x.png", "scale" : "1x" }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
JSON

echo
echo "✅ Eksakt master er nå brukt"
echo "Gjør nå:"
echo "1) slett appen fra iPhone"
echo "2) restart iPhone"
echo "3) flutter clean"
echo "4) flutter pub get"
echo "5) open ios/Runner.xcworkspace"
echo "6) Product > Clean Build Folder"
echo "7) Run"
