#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ICON="$ROOT_DIR/assets/app_icons/app_icon_master.png"

echo "==> patch_732_apply_final_bonusvarsel_icon"

if [ ! -f "$ICON" ]; then
  echo "❌ Mangler ikon:"
  echo "   $ICON"
  exit 1
fi

python3 -m pip install --quiet pillow || true

echo "==> Genererer iOS ikoner"

python3 <<PY
from PIL import Image
import os

src = r"$ICON"
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
    img.resize((size, size), Image.LANCZOS).save(out, format="PNG")
    print("✔", name)
PY

echo "==> Rydder cache"
flutter clean >/dev/null 2>&1 || true
rm -rf build/ios || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "✅ Ferdig"
echo "Gjør dette nå:"
echo "1) Slett appen fra iPhone"
echo "2) Restart iPhone"
echo "3) flutter pub get"
echo "4) flutter run -d 00008110-001138643E60401E"
