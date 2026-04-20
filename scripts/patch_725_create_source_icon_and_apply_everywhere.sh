#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="assets/app_icons"
SRC_ICON="$SRC_DIR/source_icon.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES="android/app/src/main/res"

if [ ! -d "$IOS_DIR" ]; then
  echo "❌ Fant ikke $IOS_DIR"
  exit 1
fi

if [ ! -d "$ANDROID_RES" ]; then
  echo "❌ Fant ikke $ANDROID_RES"
  exit 1
fi

mkdir -p "$SRC_DIR"
cp -R "$IOS_DIR" "${IOS_DIR}.bak_725_$(date +%s)"
echo "✅ Backup laget av iOS AppIcon-settet"

python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json

src_dir = Path("assets/app_icons")
src_dir.mkdir(parents=True, exist_ok=True)
src_icon = src_dir / "source_icon.png"

size = 1024
img = Image.new("RGBA", (size, size), (9, 24, 67, 255))
draw = ImageDraw.Draw(img)

# myk blå glow
glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
g = ImageDraw.Draw(glow)
for r, a in [(420, 18), (300, 28), (220, 36)]:
    g.ellipse((512-r, 512-r, 512+r, 512+r), fill=(34, 88, 210, a))
glow = glow.filter(ImageFilter.GaussianBlur(60))
img = Image.alpha_composite(img, glow)
draw = ImageDraw.Draw(img)

# subtil gullramme
draw.rounded_rectangle(
    (52, 52, 972, 972),
    radius=220,
    outline=(229, 197, 104, 185),
    width=8,
)

# bakre kort
draw.rounded_rectangle(
    (170, 240, 790, 730),
    radius=92,
    fill=(13, 39, 108, 255),
    outline=(228, 196, 100, 170),
    width=8,
)

# fremre kort
draw.rounded_rectangle(
    (235, 305, 865, 815),
    radius=96,
    fill=(18, 53, 140, 255),
    outline=(240, 208, 112, 255),
    width=10,
)

# stripe på kortet
draw.rounded_rectangle(
    (325, 445, 790, 468),
    radius=10,
    fill=(240, 208, 112, 255),
)

# skygge under stjerne
shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
star = [(548, 392), (580, 476), (668, 488), (602, 544), (624, 632),
        (548, 590), (472, 632), (494, 544), (428, 488), (516, 476)]
sd.polygon([(x+10, y+12) for x, y in star], fill=(0, 0, 0, 120))
shadow = shadow.filter(ImageFilter.GaussianBlur(16))
img = Image.alpha_composite(img, shadow)

draw = ImageDraw.Draw(img)
draw.polygon(star, fill=(247, 209, 72, 255))

# liten glimt oppe til venstre
spark = [(246, 208), (262, 248), (302, 262), (264, 276), (250, 316), (236, 276), (196, 262), (234, 248)]
draw.polygon(spark, fill=(255, 236, 174, 255))

# lagre kildeikon
img.convert("RGB").save(src_icon, "PNG", optimize=True)
print(f"✅ Laget {src_icon}")

# skriv iOS app icons
ios_dir = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
base = Image.open(src_icon).convert("RGB")

# slett gamle png-er
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
    base.resize((px, px)).save(out, "PNG")
    images.append({
        "size": size_str,
        "idiom": idiom,
        "filename": filename,
        "scale": scale,
    })

contents = {
    "images": images,
    "info": {"version": 1, "author": "xcode"},
}
(ios_dir / "Contents.json").write_text(json.dumps(contents, indent=2))
print("✅ Skrev nye iOS AppIcon-filer")

# skriv Android-ikoner
android_res = Path("android/app/src/main/res")
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
    out = android_res / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    base.resize((px, px)).save(out, "PNG")

print("✅ Skrev nye Android launcher-ikoner")
PY

echo
echo "==> rydder cache"
flutter clean || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "==> flutter pub get"
flutter pub get

echo
echo "==> verifiser kildeikon"
file "$SRC_ICON" || true

echo
echo "==> verifiser nye tidsstempler"
ls -la "$IOS_DIR"

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "✅ Ferdig."
echo
echo "Gjør nå dette NØYAKTIG:"
echo "  1) SLETT appen helt fra iPhone"
echo "  2) restart iPhone"
echo "  3) flutter run -d 00008110-001138643E60401E"
echo "  4) sjekk at ikonet ikke lenger er Flutter-F eller grå placeholder"
