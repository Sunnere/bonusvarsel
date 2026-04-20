#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_748_use_exact_uploaded_icon_and_lock"

MASTER="assets/app_icons/app_icon_master.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

mkdir -p assets/app_icons
mkdir -p "$IOS_DIR"

echo "==> Legg inn bildet manuelt først!"
echo
echo "📌 Gjør dette nå:"
echo "1) Høyreklikk bildet du fikk i chat"
echo "2) Lagre som:"
echo "   $HOME/Downloads/bonusvarsel_master.png"
echo
read -p "Trykk ENTER når du har lagret bildet..."

SOURCE_ICON="$HOME/Downloads/bonusvarsel_master.png"

if [ ! -f "$SOURCE_ICON" ]; then
  echo "❌ Fant ikke fil:"
  echo "   $SOURCE_ICON"
  exit 1
fi

echo "==> Kopierer eksakt master"
cp "$SOURCE_ICON" "$MASTER"

echo "==> Verifiserer"
file "$MASTER"
ls -lh "$MASTER"

python3 -m pip install --quiet pillow >/dev/null 2>&1 || true

echo "==> Genererer iOS ikoner (uten endringer i design)"
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
    img.resize((px, px), Image.Resampling.LANCZOS).save(
        os.path.join(dst, name),
        format="PNG",
        optimize=False,
        compress_level=0
    )
    print("✅", name)
PY

echo "==> Ferdig. Nå MÅ du gjøre dette:"
echo
echo "1) Slett app fra iPhone"
echo "2) Restart iPhone"
echo "3) flutter clean"
echo "4) flutter pub get"
echo "5) open ios/Runner.xcworkspace"
echo "6) Product > Clean Build Folder"
echo "7) flutter run -d 00008110-001138643E60401E"
