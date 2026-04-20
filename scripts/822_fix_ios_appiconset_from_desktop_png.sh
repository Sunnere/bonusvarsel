#!/usr/bin/env bash
set -euo pipefail

echo "==> 822_fix_ios_appiconset_from_desktop_png"

ICON_SRC="${1:-$HOME/Desktop/app_icon_1024.png}"
APPICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$ICON_SRC" ]; then
  echo "❌ Fant ikke ikonfil: $ICON_SRC"
  exit 1
fi

mkdir -p "$APPICON_DIR"

python3 - <<'PY' "$ICON_SRC" "$APPICON_DIR"
import json
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("❌ Pillow mangler. Kjør: python3 -m pip install Pillow")
    raise SystemExit(1)

src = Path(sys.argv[1])
out_dir = Path(sys.argv[2])

img = Image.open(src).convert("RGBA")
if img.size != (1024, 1024):
    print(f"⚠️ Skalerer ikon fra {img.size} til 1024x1024")
    img = img.resize((1024, 1024), Image.LANCZOS)

# Fjern alpha
bg = Image.new("RGB", img.size, (255, 255, 255))
if "A" in img.getbands():
    bg.paste(img, mask=img.getchannel("A"))
else:
    bg.paste(img)
img = bg

# Slett gamle png-filer i AppIcon-settet
for f in out_dir.glob("*.png"):
    f.unlink()

specs = [
    # iPhone Notifications
    ("iphone", "20x20", "2x", 40,  "Icon-App-20x20@2x.png"),
    ("iphone", "20x20", "3x", 60,  "Icon-App-20x20@3x.png"),

    # iPhone Settings
    ("iphone", "29x29", "2x", 58,  "Icon-App-29x29@2x.png"),
    ("iphone", "29x29", "3x", 87,  "Icon-App-29x29@3x.png"),

    # iPhone Spotlight
    ("iphone", "40x40", "2x", 80,  "Icon-App-40x40@2x.png"),
    ("iphone", "40x40", "3x", 120, "Icon-App-40x40@3x.png"),

    # iPhone App
    ("iphone", "60x60", "2x", 120, "Icon-App-60x60@2x.png"),
    ("iphone", "60x60", "3x", 180, "Icon-App-60x60@3x.png"),

    # iPad Notifications
    ("ipad", "20x20", "1x", 20, "Icon-App-20x20@1x.png"),
    ("ipad", "20x20", "2x", 40, "Icon-App-20x20@2x-1.png"),

    # iPad Settings
    ("ipad", "29x29", "1x", 29, "Icon-App-29x29@1x.png"),
    ("ipad", "29x29", "2x", 58, "Icon-App-29x29@2x-1.png"),

    # iPad Spotlight
    ("ipad", "40x40", "1x", 40, "Icon-App-40x40@1x.png"),
    ("ipad", "40x40", "2x", 80, "Icon-App-40x40@2x-1.png"),

    # iPad App
    ("ipad", "76x76", "1x", 76,  "Icon-App-76x76@1x.png"),
    ("ipad", "76x76", "2x", 152, "Icon-App-76x76@2x.png"),

    # iPad Pro
    ("ipad", "83.5x83.5", "2x", 167, "Icon-App-83.5x83.5@2x.png"),

    # App Store
    ("ios-marketing", "1024x1024", "1x", 1024, "Icon-App-1024x1024@1x.png"),
]

images = []
for idiom, size, scale, px, filename in specs:
    resized = img.resize((px, px), Image.LANCZOS)
    resized.save(out_dir / filename, format="PNG")
    images.append({
        "size": size,
        "idiom": idiom,
        "filename": filename,
        "scale": scale
    })

contents = {
    "images": images,
    "info": {
        "version": 1,
        "author": "xcode"
    }
}

(out_dir / "Contents.json").write_text(
    json.dumps(contents, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8"
)

print(f"✅ Skrev {len(images)} ikonfiler")
print(f"✅ Skrev {out_dir / 'Contents.json'}")
PY

# Fjern ekstra AppIcon-varianter som bare lager rot
rm -rf "ios/Runner/Assets.xcassets/AppIcon 1.appiconset" 2>/dev/null || true
rm -rf "ios/Runner/Assets.xcassets/AppIcon1.appiconset" 2>/dev/null || true

echo "✅ 822 ferdig"
echo
echo "Kjør nå:"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter build ipa"
