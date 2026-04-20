#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ASSETS="$ROOT/assets/app_icons"
MASTER="$ASSETS/app_icon_master.png"

echo "==> patch_734_force_ios_icon_full_reset"

mkdir -p "$ASSETS"
mkdir -p "$IOS"

echo "==> Skriver master ikon (embedded)"

python3 <<'PY'
from PIL import Image, ImageDraw

# Lager et enkelt, garantert gyldig ikon (ingen alpha)
size = 1024
img = Image.new("RGB", (size, size), (20, 120, 70))  # grønn bakgrunn

draw = ImageDraw.Draw(img)

# enkel "fly" form (hvit)
draw.polygon([
    (200, 500),
    (850, 350),
    (900, 400),
    (300, 600)
], fill=(255,255,255))

# blått kort
draw.rectangle([500,600,900,850], fill=(30,90,200))

img.save("assets/app_icons/app_icon_master.png")
print("✅ master ikon laget")
PY

echo "==> Genererer alle iOS ikon-størrelser"

python3 <<PY
from PIL import Image
import os

src = "$MASTER"
out = "$IOS"

img = Image.open(src).convert("RGB")

sizes = {
 "Icon-App-20x20@1x.png":20,
 "Icon-App-20x20@2x.png":40,
 "Icon-App-20x20@3x.png":60,
 "Icon-App-29x29@1x.png":29,
 "Icon-App-29x29@2x.png":58,
 "Icon-App-29x29@3x.png":87,
 "Icon-App-40x40@1x.png":40,
 "Icon-App-40x40@2x.png":80,
 "Icon-App-40x40@3x.png":120,
 "Icon-App-60x60@2x.png":120,
 "Icon-App-60x60@3x.png":180,
 "Icon-App-76x76@1x.png":76,
 "Icon-App-76x76@2x.png":152,
 "Icon-App-83.5x83.5@2x.png":167,
 "Icon-App-1024x1024@1x.png":1024
}

for name, s in sizes.items():
    img.resize((s,s), Image.LANCZOS).save(os.path.join(out,name))
    print("✔", name)
PY

echo "==> Skriver Contents.json"

cat > "$IOS/Contents.json" <<JSON
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
    { "size" : "1024x1024", "idiom" : "ios-marketing", "filename" : "Icon-App-1024x1024@1x.png", "scale" : "1x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON

echo "==> HARD CLEAN"

flutter clean >/dev/null 2>&1 || true
rm -rf build ios/build ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "✅ Ferdig"
echo "👉 Nå gjør du dette:"
echo "1. SLETT appen fra iPhone"
echo "2. restart iPhone"
echo "3. åpne ios/Runner.xcworkspace i Xcode"
echo "4. Product > Clean Build Folder"
echo "5. RUN fra Xcode (helst med kabel)"
