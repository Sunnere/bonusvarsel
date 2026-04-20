#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ASSET_DIR="$ROOT_DIR/assets/app_icons"
MASTER_ICON="$ASSET_DIR/app_icon_master.png"
BACKUP_DIR="$IOS_DIR.bak_730_$(date +%Y%m%d_%H%M%S)"

echo "==> patch_730_rebuild_ios_icons_from_master_png"

if [ ! -d "$IOS_DIR" ]; then
  echo "❌ Fant ikke appicon-mappen:"
  echo "   $IOS_DIR"
  exit 1
fi

if [ ! -f "$MASTER_ICON" ]; then
  echo "❌ Fant ikke master-ikonet:"
  echo "   $MASTER_ICON"
  echo
  echo "Lag først en gyldig PNG i Preview og lagre den som:"
  echo "   assets/app_icons/app_icon_master.png"
  exit 1
fi

echo "==> Installerer Pillow hvis nødvendig"
python3 -m pip install --quiet pillow || true

echo "==> Verifiserer inputfil"
python3 <<PY
from PIL import Image
path = r"$MASTER_ICON"
img = Image.open(path)
img.load()
print("✅ OK:", path, img.size, img.mode)
PY

echo "==> Tar backup"
cp -R "$IOS_DIR" "$BACKUP_DIR"
echo "✅ Backup laget: $BACKUP_DIR"

echo "==> Sletter gamle ikonfiler"
find "$IOS_DIR" -maxdepth 1 -type f -name 'Icon-App-*.png' -delete

echo "==> Genererer nye ikonfiler"
python3 <<PY
from PIL import Image
import os

src = r"$MASTER_ICON"
out_dir = r"$IOS_DIR"

img = Image.open(src).convert("RGBA")

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

for name, size in sizes.items():
    out = os.path.join(out_dir, name)
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(out, format="PNG")
    print("✅", name, size)
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

echo "==> Filstørrelser"
ls -lh "$IOS_DIR"
ls -lh "$MASTER_ICON"

echo "==> Rydder cache"
flutter clean >/dev/null 2>&1 || true
rm -rf "$ROOT_DIR/build/ios" || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "✅ Ferdig"
echo "Gjør nå:"
echo "1) Slett appen fra iPhone"
echo "2) Restart iPhone"
echo "3) flutter pub get"
echo "4) flutter run -d 00008110-001138643E60401E"
