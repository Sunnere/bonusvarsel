#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ICON="assets/app_icons/app_icon_master.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES="android/app/src/main/res"

echo "==> patch_742_lock_favorite_icon_as_master"

# 1. Sjekk at master finnes
if [ ! -f "$ICON" ]; then
  echo "❌ Mangler master ikon:"
  echo "   $ICON"
  echo ""
  echo "Legg favorittbildet ditt der først (1024x1024 PNG)"
  exit 1
fi

echo "==> Verifiserer ikon"
file "$ICON"

mkdir -p "$IOS_DIR"

echo "==> Genererer iOS ikoner (fra låst master)"

python3 - <<PY
from PIL import Image
import os

src = "$ICON"
dst = "$IOS_DIR"

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
    img.resize((px, px), Image.Resampling.LANCZOS).save(
        os.path.join(dst, name),
        format="PNG",
        optimize=False,
        compress_level=0
    )
    print("✅", name)
PY

echo "==> Skriver Contents.json"

cat > "$IOS_DIR/Contents.json" <<JSON
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

echo "==> Rydder cache"

flutter clean >/dev/null 2>&1 || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "✅ MASTER IKON LÅST"
echo
echo "Gjør nå:"
echo "1) Slett app fra iPhone"
echo "2) Restart iPhone"
echo "3) flutter pub get"
echo "4) flutter run"
