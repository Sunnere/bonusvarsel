#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

IOS_DIR="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES="$ROOT/android/app/src/main/res"
ASSET_DIR="$ROOT/assets/app_icons"
MASTER="$ASSET_DIR/app_icon_master.png"

echo "==> patch_737_make_icon_bolder_and_rebuild"

mkdir -p "$ASSET_DIR"
mkdir -p "$IOS_DIR"

python3 -m pip install --quiet pillow >/dev/null 2>&1 || true

python3 <<'PY'
from PIL import Image, ImageDraw, ImageFilter

size = 1024
img = Image.new("RGB", (size, size), (18, 103, 63))
draw = ImageDraw.Draw(img)

# Bakgrunn med svak radial glow
glow = Image.new("RGB", (size, size), (18, 103, 63))
gdraw = ImageDraw.Draw(glow)
for r, alpha in [(420, 40), (320, 55), (220, 70)]:
    x0 = size//2 - r
    y0 = size//2 - r
    x1 = size//2 + r
    y1 = size//2 + r
    gdraw.ellipse((x0, y0, x1, y1), fill=(70+alpha, 180, 90))
glow = glow.filter(ImageFilter.GaussianBlur(60))
img = Image.blend(img, glow, 0.28)
draw = ImageDraw.Draw(img)

# Mørk vignette for mer punch
overlay = Image.new("RGBA", (size, size), (0,0,0,0))
od = ImageDraw.Draw(overlay)
od.rounded_rectangle((8, 8, size-8, size-8), radius=220, outline=(255,255,255,26), width=3)
img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
draw = ImageDraw.Draw(img)

# Blått kort - større, tydeligere
card = (520, 560, 900, 835)
draw.rounded_rectangle(card, radius=34, fill=(28, 92, 222), outline=(138, 186, 255), width=8)
# kort-shine
draw.polygon([(545,590),(850,590),(895,625),(585,625)], fill=(90, 145, 255))
# chip
draw.rounded_rectangle((595,655,655,710), radius=10, fill=(224, 194, 98))
# liten markør
draw.rounded_rectangle((815,700,875,760), radius=12, fill=(74, 128, 235))

# Mynter - tykkere, enklere
def coin(cx, cy, w=180, h=56):
    draw.ellipse((cx-w//2, cy-h//2, cx+w//2, cy+h//2), fill=(220, 182, 52), outline=(255, 226, 126), width=6)
    draw.rectangle((cx-w//2, cy, cx+w//2, cy+34), fill=(196, 156, 34))
    draw.ellipse((cx-w//2, cy+18, cx+w//2, cy+18+h), fill=(209, 168, 42), outline=(170, 132, 25), width=4)

coin(345, 735, 200, 58)
coin(420, 665, 170, 52)

# Fly - mye tykkere og enklere
# skygge
shadow = Image.new("RGBA", (size, size), (0,0,0,0))
sd = ImageDraw.Draw(shadow)
sd.polygon([
    (205, 500), (730, 340), (890, 360), (760, 425),
    (640, 455), (720, 520), (660, 545), (575, 480),
    (450, 520), (365, 605), (305, 595), (380, 510),
    (255, 535)
], fill=(0,0,0,70))
shadow = shadow.filter(ImageFilter.GaussianBlur(12))
img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")
draw = ImageDraw.Draw(img)

# kropp
body = [
    (190, 470), (710, 315), (902, 340), (760, 425),
    (640, 450), (735, 520), (670, 545), (560, 470),
    (420, 510), (330, 610), (270, 595), (350, 505),
    (230, 525)
]
draw.polygon(body, fill=(245, 248, 250), outline=(210, 220, 228))

# vinger og hale
draw.polygon([(420,510),(250,425),(300,415),(495,485)], fill=(248,250,252))
draw.polygon([(375,555),(230,595),(275,625),(420,585)], fill=(238,242,246))
draw.polygon([(250,525),(185,565),(235,585),(300,545)], fill=(238,242,246))

# cockpit og vinduer
draw.ellipse((825,345,848,358), fill=(86, 110, 145))
for i in range(9):
    x = 650 + i*18
    draw.ellipse((x, 378, x+7, 385), fill=(110, 128, 146))

# motorer
for cx, cy in [(630,455),(790,432)]:
    draw.ellipse((cx-34, cy-28, cx+34, cy+28), fill=(50, 79, 95))
    draw.ellipse((cx-20, cy-15, cx+20, cy+15), fill=(14, 27, 36))

# Lagre som opaque PNG
img.save("assets/app_icons/app_icon_master.png", format="PNG", optimize=False, compress_level=0)
print("✅ wrote assets/app_icons/app_icon_master.png")
PY

python3 <<PY
from PIL import Image
import os

src = "$MASTER"
ios_dir = "$IOS_DIR"
android_res = "$ANDROID_RES"

img = Image.open(src).convert("RGB")

ios_sizes = {
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
for name, px in ios_sizes.items():
    img.resize((px, px), Image.Resampling.LANCZOS).save(os.path.join(ios_dir, name), format="PNG", optimize=False, compress_level=0)

android_sizes = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
}
for rel, px in android_sizes.items():
    out = os.path.join(android_res, rel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.resize((px, px), Image.Resampling.LANCZOS).save(out, format="PNG", optimize=False, compress_level=0)

print("✅ regenerated iOS + Android launcher icons")
PY

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

flutter clean >/dev/null 2>&1 || true
rm -rf build ios/build ~/Library/Developer/Xcode/DerivedData/* || true

echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) slett appen fra iPhone"
echo "2) flutter pub get"
echo "3) flutter run -d 00008110-001138643E60401E"
