#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ICON_PATH="assets/app_icons/app_icon_master.png"
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo "==> patch_740_fix_ios_generated_xcconfig_then_apply_icon"

if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Fant ikke pubspec.yaml. Kjør fra bonusvarsel-repoet."
  exit 1
fi

if [ ! -f "$ICON_PATH" ]; then
  echo "❌ Mangler ikonfil: $ICON_PATH"
  echo "Legg den valgte PNG-filen der først."
  exit 1
fi

mkdir -p ios/Flutter
mkdir -p "$IOS_ICON_DIR"

echo
echo "==> Backup av viktige filer"
cp -f ios/Podfile "ios/Podfile.bak_740_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Debug.xcconfig "ios/Flutter/Debug.xcconfig.bak_740_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Release.xcconfig "ios/Flutter/Release.xcconfig.bak_740_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Profile.xcconfig "ios/Flutter/Profile.xcconfig.bak_740_$(date +%Y%m%d_%H%M%S)" || true

echo
echo "==> Rydder build/cache (ikke Generated.xcconfig)"
rm -rf build
rm -rf ios/build
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "==> flutter pub get"
flutter pub get

echo
echo "==> precache iOS"
flutter precache --ios

echo
echo "==> regenererer Flutter iOS-filer"
flutter build ios --debug --no-codesign

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "❌ ios/Flutter/Generated.xcconfig ble ikke laget"
  exit 1
fi

echo "✅ Fant ios/Flutter/Generated.xcconfig"

echo
echo "==> skriver stabile xcconfig-filer"
cat > ios/Flutter/Debug.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
XCCONFIG

cat > ios/Flutter/Release.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
XCCONFIG

cat > ios/Flutter/Profile.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
XCCONFIG

echo
echo "==> pod install"
cd ios
pod install
cd ..

echo
echo "==> genererer appikoner med Python"
python3 -m pip install --quiet pillow >/dev/null 2>&1 || true

python3 <<PY
from PIL import Image
import os

src = r"$ICON_PATH"
out_dir = r"$IOS_ICON_DIR"

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
        os.path.join(out_dir, name),
        format="PNG",
        optimize=False,
        compress_level=0,
    )
    print("✅", name)
PY

echo
echo "==> skriver Contents.json"
cat > "$IOS_ICON_DIR/Contents.json" <<'JSON'
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
echo "==> verifisering"
ls -lh ios/Flutter/Generated.xcconfig
ls -lh "$ICON_PATH"
ls -lh "$IOS_ICON_DIR"/Icon-App-1024x1024@1x.png

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) slett appen fra iPhone"
echo "2) restart iPhone"
echo "3) open ios/Runner.xcworkspace"
echo "4) Product > Clean Build Folder"
echo "5) flutter run -d 00008110-001138643E60401E"
