#!/usr/bin/env bash
set -euo pipefail

echo "==> 821_generate_ios_appicons_from_desktop_png"

ICON_SRC="${1:-$HOME/Desktop/app_icon_1024.png}"
APPICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
CONTENTS_JSON="$APPICON_DIR/Contents.json"

if [ ! -f "$ICON_SRC" ]; then
  echo "❌ Fant ikke ikonfil: $ICON_SRC"
  echo "Legg filen her eller send sti som parameter."
  exit 1
fi

mkdir -p "$APPICON_DIR"

python3 <<'PY' "$ICON_SRC" "$APPICON_DIR" "$CONTENTS_JSON"
import json
import os
import sys
from pathlib import Path

src = Path(sys.argv[1])
out_dir = Path(sys.argv[2])
contents_json = Path(sys.argv[3])

try:
    from PIL import Image
except ImportError:
    print("❌ Pillow mangler. Kjør: python3 -m pip install Pillow")
    sys.exit(1)

img = Image.open(src).convert("RGBA")
if img.size != (1024, 1024):
    print(f"⚠️ Kildeikon er {img.size}, ikke 1024x1024. Skalerer automatisk til 1024x1024.")
    img = img.resize((1024, 1024), Image.LANCZOS)

# Fjern alpha ved å lime på hvit bakgrunn hvis nødvendig
if "A" in img.getbands():
    bg = Image.new("RGB", img.size, (255, 255, 255))
    bg.paste(img, mask=img.getchannel("A"))
    img = bg
else:
    img = img.convert("RGB")

specs = [
    # iPhone notification
    ("iphone", "20x20", "2x", 40, "Icon-App-20x20@2x.png"),
    ("iphone", "20x20", "3x", 60, "Icon-App-20x20@3x.png"),
    # iPhone settings
    ("iphone", "29x29", "2x", 58, "Icon-App-29x29@2x.png"),
    ("iphone", "29x29", "3x", 87, "Icon-App-29x29@3x.png"),
    # iPhone spotlight
    ("iphone", "40x40", "2x", 80, "Icon-App-40x40@2x.png"),
    ("iphone", "40x40", "3x", 120, "Icon-App-40x40@3x.png"),
    # iPhone app
    ("iphone", "60x60", "2x", 120, "Icon-App-60x60@2x.png"),
    ("iphone", "60x60", "3x", 180, "Icon-App-60x60@3x.png"),

    # iPad notifications
    ("ipad", "20x20", "1x", 20, "Icon-App-20x20@1x.png"),
    ("ipad", "20x20", "2x", 40, "Icon-App-20x20@2x~ipad.png"),
    # iPad settings
    ("ipad", "29x29", "1x", 29, "Icon-App-29x29@1x.png"),
    ("ipad", "29x29", "2x", 58, "Icon-App-29x29@2x~ipad.png"),
    # iPad spotlight
    ("ipad", "40x40", "1x", 40, "Icon-App-40x40@1x.png"),
    ("ipad", "40x40", "2x", 80, "Icon-App-40x40@2x~ipad.png"),
    # iPad app
    ("ipad", "76x76", "1x", 76, "Icon-App-76x76@1x.png"),
    ("ipad", "76x76", "2x", 152, "Icon-App-76x76@2x.png"),
    # iPad Pro app
    ("ipad", "83.5x83.5", "2x", 167, "Icon-App-83.5x83.5@2x.png"),

    # App Store
    ("ios-marketing", "1024x1024", "1x", 1024, "Icon-App-1024x1024@1x.png"),
]

images = []
for idiom, size, scale, px, filename in specs:
    resized = img.resize((px, px), Image.LANCZOS)
    resized.save(out_dir / filename, format="PNG")
    entry = {
        "idiom": idiom,
        "size": size,
        "scale": scale,
        "filename": filename,
    }
    images.append(entry)

contents = {
    "images": images,
    "info": {
        "version": 1,
        "author": "xcode"
    }
}
contents_json.write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
print(f"✅ Skrev {len(images)} ikonfiler til {out_dir}")
print(f"✅ Skrev {contents_json}")
PY

echo "✅ Ferdig"
echo
echo "Kjør nå:"
echo "  open ios/Runner.xcworkspace"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter build ipa"
