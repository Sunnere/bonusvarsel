#!/usr/bin/env bash
set -euo pipefail

IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES_DIR="android/app/src/main/res"
OUT_ICON="assets/app_icons/bonusvarsel_app_icon_final.png"

if [ ! -d "$IOS_ICON_DIR" ]; then
  echo "❌ Fant ikke $IOS_ICON_DIR"
  exit 1
fi

if [ ! -d "$ANDROID_RES_DIR" ]; then
  echo "❌ Fant ikke $ANDROID_RES_DIR"
  exit 1
fi

mkdir -p assets/app_icons
cp -R "$IOS_ICON_DIR" "${IOS_ICON_DIR}.bak_717_$(date +%s)"
echo "✅ Backup laget av iOS AppIcon-settet"

python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

size = 1024
img = Image.new("RGBA", (size, size), (10, 26, 74, 255))
draw = ImageDraw.Draw(img)

# Soft blue vignette / glow
glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
g = ImageDraw.Draw(glow)
for r, a in [(420, 18), (320, 26), (240, 34)]:
    g.ellipse((512-r, 512-r, 512+r, 512+r), fill=(38, 84, 180, a))
glow = glow.filter(ImageFilter.GaussianBlur(55))
img = Image.alpha_composite(img, glow)

draw = ImageDraw.Draw(img)

# Outer subtle gold border
draw.rounded_rectangle(
    (46, 46, 978, 978),
    radius=220,
    outline=(224, 192, 92, 170),
    width=6,
)

# Back card
draw.rounded_rectangle(
    (170, 230, 820, 760),
    radius=90,
    fill=(13, 34, 98, 255),
    outline=(227, 195, 92, 220),
    width=10,
)

# Front card
draw.rounded_rectangle(
    (220, 290, 875, 805),
    radius=92,
    fill=(21, 48, 125, 255),
    outline=(232, 201, 98, 255),
    width=10,
)

# Top stripe on front card
draw.rounded_rectangle(
    (290, 420, 790, 440),
    radius=10,
    fill=(232, 201, 98, 255),
)

# Shadow under star
shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
star = [(542, 372), (582, 470), (688, 482), (607, 548), (631, 653),
        (542, 598), (453, 653), (477, 548), (396, 482), (502, 470)]
sd.polygon([(x+8, y+12) for x,y in star], fill=(0,0,0,110))
shadow = shadow.filter(ImageFilter.GaussianBlur(16))
img = Image.alpha_composite(img, shadow)
draw = ImageDraw.Draw(img)

# Gold star
draw.polygon(star, fill=(241, 200, 62, 255))

# Small sparkle
spark = [(250, 206), (264, 242), (301, 255), (266, 268), (253, 305), (239, 268), (203, 255), (239, 242)]
draw.polygon(spark, fill=(255, 235, 170, 255))

# Save master icon
out = Path("assets/app_icons/bonusvarsel_app_icon_final.png")
out.parent.mkdir(parents=True, exist_ok=True)
img.convert("RGB").save(out, "PNG", optimize=True)
print(f"✅ Laget ikon: {out}")
PY

python3 - <<'PY'
from pathlib import Path
from PIL import Image

src = Path("assets/app_icons/bonusvarsel_app_icon_final.png")
ios = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
android = Path("android/app/src/main/res")
img = Image.open(src).convert("RGBA")

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
    img.resize((px, px)).convert("RGB").save(ios / name, "PNG")

android_targets = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
    "mipmap-mdpi/ic_launcher_round.png": 48,
    "mipmap-hdpi/ic_launcher_round.png": 72,
    "mipmap-xhdpi/ic_launcher_round.png": 96,
    "mipmap-xxhdpi/ic_launcher_round.png": 144,
    "mipmap-xxxhdpi/ic_launcher_round.png": 192,
}
for rel, px in android_targets.items():
    out = android / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    img.resize((px, px)).convert("RGBA").save(out, "PNG")

print("✅ Skrev nye iOS- og Android-ikoner")
PY

echo
echo "==> flutter clean"
flutter clean

echo
echo "==> flutter pub get"
flutter pub get

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "✅ Ferdig."
echo
echo "Neste steg:"
echo "  1) SLETT appen helt fra iPhone"
echo "  2) flutter run -d 00008110-001138643E60401E"
echo "  3) sjekk at ikonet på hjemskjermen ikke lenger er Flutter-F"
echo "  4) bygg NY iOS build"
echo "  5) last opp ny build til App Store Connect"
