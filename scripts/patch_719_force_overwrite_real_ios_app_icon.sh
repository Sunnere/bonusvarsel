#!/usr/bin/env bash
set -euo pipefail

IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -d "$IOS_ICON_DIR" ]; then
  echo "❌ Fant ikke $IOS_ICON_DIR"
  exit 1
fi

STAMP="$(date +%s)"
cp -R "$IOS_ICON_DIR" "${IOS_ICON_DIR}.bak_${STAMP}"
echo "✅ Backup laget: ${IOS_ICON_DIR}.bak_${STAMP}"

mkdir -p assets/app_icons

python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json

ios_dir = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
master = Path("assets/app_icons/bonusvarsel_icon_1024.png")

# Lag et ikon som umulig kan forveksles med Flutter-F
size = 1024
img = Image.new("RGBA", (size, size), (10, 28, 70, 255))
draw = ImageDraw.Draw(img)

# bakgrunnsglow
glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
g = ImageDraw.Draw(glow)
for r, a in [(430, 20), (320, 28), (240, 36)]:
    g.ellipse((512-r, 512-r, 512+r, 512+r), fill=(28, 120, 90, a))
glow = glow.filter(ImageFilter.GaussianBlur(56))
img = Image.alpha_composite(img, glow)

draw = ImageDraw.Draw(img)

# ytre ramme
draw.rounded_rectangle(
    (52, 52, 972, 972),
    radius=220,
    outline=(228, 196, 98, 190),
    width=7,
)

# kort bak
draw.rounded_rectangle(
    (170, 230, 820, 760),
    radius=88,
    fill=(15, 40, 108, 255),
    outline=(232, 201, 98, 220),
    width=10,
)

# kort foran
draw.rounded_rectangle(
    (230, 300, 870, 810),
    radius=94,
    fill=(18, 50, 128, 255),
    outline=(238, 208, 108, 255),
    width=10,
)

# stripe
draw.rounded_rectangle(
    (300, 420, 790, 438),
    radius=9,
    fill=(238, 208, 108, 255),
)

# skygge under stjerne
shadow = Image.new("RGBA", (size, size), (0,0,0,0))
sd = ImageDraw.Draw(shadow)
star = [(548, 372), (588, 470), (694, 482), (613, 548), (637, 653),
        (548, 598), (459, 653), (483, 548), (402, 482), (508, 470)]
sd.polygon([(x+8, y+12) for x, y in star], fill=(0, 0, 0, 115))
shadow = shadow.filter(ImageFilter.GaussianBlur(16))
img = Image.alpha_composite(img, shadow)

draw = ImageDraw.Draw(img)
draw.polygon(star, fill=(243, 201, 62, 255))

# liten bonus-glimt
spark = [(248, 206), (264, 244), (302, 258), (266, 272), (252, 308), (238, 272), (202, 258), (238, 244)]
draw.polygon(spark, fill=(255, 236, 172, 255))

# Lagre master
master.parent.mkdir(parents=True, exist_ok=True)
img.convert("RGB").save(master, "PNG", optimize=True)

# Slett gamle png-er i AppIcon-settet
for f in ios_dir.glob("*.png"):
    f.unlink()

# Skriv alle iOS-ikonfilene på nytt
img = Image.open(master).convert("RGBA")
sizes = [
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
for filename, px, idiom, size_str, scale in sizes:
    img.resize((px, px)).convert("RGB").save(ios_dir / filename, "PNG")
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

print("✅ Skrev nytt Bonusvarsel-ikon til iOS AppIcon.appiconset")
print("✅ Master:", master)
PY

echo
echo "==> rydder cache"
flutter clean || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "==> flutter pub get"
flutter pub get

echo
echo "==> verifiserer nye tidsstempler"
ls -la "$IOS_ICON_DIR"

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
echo "  4) sjekk ikon på hjemskjermen"
echo
echo "Hvis du vil sjekke at filene faktisk ble skrevet nå:"
echo "  ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset"
