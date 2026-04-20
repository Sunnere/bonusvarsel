#!/usr/bin/env bash
set -euo pipefail

SRC="assets/app_icons/source_icon.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo "==> Sjekker kildeikon"
if [ ! -f "$SRC" ]; then
  echo "❌ Fant ikke $SRC"
  echo "Legg blå/gull-ikonet ditt her først:"
  echo "  assets/app_icons/source_icon.png"
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
from PIL import Image

src = Path("assets/app_icons/source_icon.png")
img = Image.open(src)
print(f"✅ source_icon funnet: {src}")
print(f"✅ størrelse: {img.size}")
if img.size != (1024, 1024):
    raise SystemExit("❌ source_icon.png må være 1024x1024")
PY

if [ ! -d "$IOS_DIR" ]; then
  echo "❌ Fant ikke $IOS_DIR"
  exit 1
fi

STAMP="$(date +%s)"
cp -R "$IOS_DIR" "${IOS_DIR}.bak_${STAMP}"
echo "✅ Backup laget: ${IOS_DIR}.bak_${STAMP}"

python3 - <<'PY'
from pathlib import Path
from PIL import Image
import json

src = Path("assets/app_icons/source_icon.png")
ios_dir = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")

img = Image.open(src).convert("RGB")

# slett gamle png-filer
for f in ios_dir.glob("*.png"):
    f.unlink()

entries = [
    ("Icon-App-20x20@1x.png", 20, "ipad", "20x20", "1x"),
    ("Icon-App-20x20@2x.png", 40, "iphone", "20x20", "2x"),
    ("Icon-App-20x20@3x.png", 60, "iphone", "20x20", "3x"),
    ("Icon-App-29x29@1x.png", 29, "iphone", "29x29", "1x"),
    ("Icon-App-29x29@2x.png", 58, "iphone", "29x29", "2x"),
    ("Icon-App-29x29@3x.png", 87, "iphone", "29x29", "3x"),
    ("Icon-App-40x40@1x.png", 40, "ipad", "40x40", "1x"),
    ("Icon-App-40x40@2x.png", 80, "iphone", "40x40", "2x"),
    ("Icon-App-40x40@3x.png", 120, "iphone", "40x40", "3x"),
    ("Icon-App-60x60@2x.png", 120, "iphone", "60x60", "2x"),
    ("Icon-App-60x60@3x.png", 180, "iphone", "60x60", "3x"),
    ("Icon-App-76x76@1x.png", 76, "ipad", "76x76", "1x"),
    ("Icon-App-76x76@2x.png", 152, "ipad", "76x76", "2x"),
    ("Icon-App-83.5x83.5@2x.png", 167, "ipad", "83.5x83.5", "2x"),
    ("Icon-App-1024x1024@1x.png", 1024, "ios-marketing", "1024x1024", "1x"),
]

images = []
for filename, px, idiom, size_str, scale in entries:
    out = ios_dir / filename
    img.resize((px, px)).save(out, "PNG")
    images.append({
        "size": size_str,
        "idiom": idiom,
        "filename": filename,
        "scale": scale,
    })

contents = {
    "images": images,
    "info": {
        "version": 1,
        "author": "xcode"
    }
}
(ios_dir / "Contents.json").write_text(json.dumps(contents, indent=2))
print("✅ Skrev nye AppIcon-filer")
PY

echo
echo "==> Nye tidsstempler i AppIcon-settet"
ls -la "$IOS_DIR"

echo
echo "==> Rydder cache"
flutter clean || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "==> flutter pub get"
flutter pub get

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "✅ FERDIG"
echo
echo "Gjør nå dette nøyaktig:"
echo "1) SLETT appen fra iPhone"
echo "2) restart iPhone"
echo "3) flutter run -d 00008110-001138643E60401E"
echo "4) sjekk ikon på hjemskjermen"
