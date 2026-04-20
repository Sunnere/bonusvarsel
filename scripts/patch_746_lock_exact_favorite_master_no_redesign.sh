#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SOURCE_ICON="${SOURCE_ICON:-$HOME/Downloads/bonusvarsel_favorite_master.png}"
MASTER="assets/app_icons/app_icon_master.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES="android/app/src/main/res"

echo "==> patch_746_lock_exact_favorite_master_no_redesign"
echo "==> SOURCE_ICON: $SOURCE_ICON"

if [ ! -f "$SOURCE_ICON" ]; then
  echo "❌ Fant ikke fast masterfil:"
  echo "   $SOURCE_ICON"
  echo
  echo "Lagre favorittbildet ditt som:"
  echo "   ~/Downloads/bonusvarsel_favorite_master.png"
  echo
  echo "Eller kjør slik med egen sti:"
  echo '   SOURCE_ICON="/full/sti/til/din/fil.png" bash scripts/patch_746_lock_exact_favorite_master_no_redesign.sh'
  exit 1
fi

mkdir -p assets/app_icons
mkdir -p "$IOS_DIR"

echo "==> Kopierer eksakt favorittfil til prosjektets master"
cp "$SOURCE_ICON" "$MASTER"

echo "==> Verifiserer master"
file "$MASTER" || true
ls -lh "$MASTER" || true

python3 -m pip install --quiet pillow >/dev/null 2>&1 || true

echo "==> Genererer iOS-ikoner fra eksakt master"
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

echo "==> Genererer Android-ikoner fra samme master"
python3 <<'PY'
from PIL import Image
import os

src = "assets/app_icons/app_icon_master.png"
res = "android/app/src/main/res"
img = Image.open(src).convert("RGB")

sizes = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
}

for rel, px in sizes.items():
    out = os.path.join(res, rel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.resize((px, px), Image.Resampling.LANCZOS).save(
        out,
        format="PNG",
        optimize=False,
        compress_level=0
    )
    print("✅", rel)
PY

echo "==> Rydder cache"
flutter clean >/dev/null 2>&1 || true
rm -rf build ios/build ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "✅ Eksakt favorittfil er nå låst som eneste master uten redesign"
echo "Kjør nå:"
echo "1) slett appen fra iPhone"
echo "2) restart iPhone"
echo "3) flutter pub get"
echo "4) open ios/Runner.xcworkspace"
echo "5) Product > Clean Build Folder"
echo "6) flutter run -d 00008110-001138643E60401E"
