#!/usr/bin/env bash
set -euo pipefail

ICON_SRC="assets/app_icons/bonusvarsel_app_icon.png"
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$ICON_SRC" ]; then
  echo "❌ Fant ikke $ICON_SRC"
  exit 1
fi

if [ ! -d "$IOS_ICON_DIR" ]; then
  echo "❌ Fant ikke $IOS_ICON_DIR"
  exit 1
fi

STAMP="$(date +%s)"
BACKUP_DIR="${IOS_ICON_DIR}.bak_${STAMP}"
cp -R "$IOS_ICON_DIR" "$BACKUP_DIR"
echo "✅ Backup laget: $BACKUP_DIR"

python3 - <<'PY'
from pathlib import Path
from PIL import Image

src = Path("assets/app_icons/bonusvarsel_app_icon.png")
dst = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")

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

for filename, px in sizes.items():
    out = img.resize((px, px))
    out.convert("RGB").save(dst / filename, "PNG")

print("✅ Alle iOS app icons skrevet direkte til AppIcon.appiconset")
PY

echo
echo "==> Rydder build-cache"
flutter clean

echo
echo "==> Henter pakker"
flutter pub get

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Neste steg:"
echo "  1) slett appen fra iPhone"
echo "  2) flutter run -d 00008110-001138643E60401E"
echo "  3) verifiser ikon på hjemskjerm"
echo "  4) bygg NY iOS build og last opp"
