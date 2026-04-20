#!/usr/bin/env bash
set -euo pipefail

SRC="assets/app_icons/source_icon.png"
DST="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SRC" ]; then
  echo "❌ Fant ikke $SRC"
  echo "Legg først ønsket ikon som: assets/app_icons/source_icon.png"
  exit 1
fi

if [ ! -d "$DST" ]; then
  echo "❌ Fant ikke $DST"
  exit 1
fi

cp -R "$DST" "${DST}.bak_720_$(date +%s)"
echo "✅ Backup laget"

python3 - <<'PY'
from pathlib import Path
from PIL import Image
import json

src = Path("assets/app_icons/source_icon.png")
dst = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")

img = Image.open(src).convert("RGB")

# slett gamle png-er
for f in dst.glob("*.png"):
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
    img.resize((px, px)).save(dst / filename, "PNG")
    images.append({
        "size": size_str,
        "idiom": idiom,
        "filename": filename,
        "scale": scale,
    })

contents = {"images": images, "info": {"version": 1, "author": "xcode"}}
(dst / "Contents.json").write_text(json.dumps(contents, indent=2))
print("✅ AppIcon.appiconset skrevet på nytt")
PY

flutter clean || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true
flutter pub get

echo
echo "✅ Ferdig."
echo "Nå gjør du:"
echo "1) slett appen fra iPhone"
echo "2) flutter run -d 00008110-001138643E60401E"
