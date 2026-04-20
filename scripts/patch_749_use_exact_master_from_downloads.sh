#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_749_use_exact_master_from_downloads"

SOURCE_ICON="$HOME/Downloads/bonusvarsel_master.png"
MASTER="assets/app_icons/app_icon_master.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo "==> Bruker:"
echo "   $SOURCE_ICON"

if [ ! -f "$SOURCE_ICON" ]; then
  echo
  echo "❌ FIL MANGLER"
  echo
  echo "Du må lagre bildet som:"
  echo "   ~/Downloads/bonusvarsel_master.png"
  echo
  echo "Gjør dette:"
  echo "1) Trykk og hold på bildet i chat"
  echo "2) Lagre bilde"
  echo "3) Gi det navn: bonusvarsel_master.png"
  echo
  exit 1
fi

mkdir -p assets/app_icons
mkdir -p "$IOS_DIR"

echo "==> Kopierer eksakt fil (ingen endringer)"
cp "$SOURCE_ICON" "$MASTER"

echo "==> Verifiserer"
file "$MASTER"
ls -lh "$MASTER"

python3 -m pip install --quiet pillow >/dev/null 2>&1 || true

echo "==> Genererer iOS ikoner"
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
echo "✅ IKON ER NÅ LÅST TIL DIN FIL"
echo
echo "Gjør dette nå:"
echo "1) Slett app fra iPhone"
echo "2) Restart iPhone"
echo "3) flutter clean"
echo "4) flutter pub get"
echo "5) open ios/Runner.xcworkspace"
echo "6) Product > Clean Build Folder"
echo "7) Run"
