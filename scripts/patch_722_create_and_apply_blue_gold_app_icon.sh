#!/usr/bin/env bash
set -euo pipefail

ICON_PATH="assets/app_icons/appstore_icon.png"

mkdir -p assets/app_icons

echo "==> Lager nytt blå/gull Bonusvarsel ikon"

python3 - <<'PY'
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

size = 1024
img = Image.new("RGBA", (size, size), (8, 22, 60, 255))
draw = ImageDraw.Draw(img)

# subtil glow
glow = Image.new("RGBA", (size, size), (0,0,0,0))
g = ImageDraw.Draw(glow)
for r, a in [(420, 20), (300, 30), (200, 40)]:
    g.ellipse((512-r,512-r,512+r,512+r), fill=(40,90,200,a))
glow = glow.filter(ImageFilter.GaussianBlur(60))
img = Image.alpha_composite(img, glow)

draw = ImageDraw.Draw(img)

# bak-kort
draw.rounded_rectangle(
    (180, 260, 820, 760),
    radius=100,
    fill=(15, 40, 110, 255),
    outline=(230,200,110,180),
    width=8
)

# front-kort
draw.rounded_rectangle(
    (240, 320, 880, 820),
    radius=110,
    fill=(20, 55, 140, 255),
    outline=(240,210,120,255),
    width=10
)

# stripe
draw.rounded_rectangle(
    (320, 460, 780, 480),
    radius=10,
    fill=(240,210,120,255)
)

# stjerne
star = [(550,420),(580,500),(660,510),(600,560),(620,640),
        (550,600),(480,640),(500,560),(440,510),(520,500)]
draw.polygon(star, fill=(255,215,90,255))

# skygge
shadow = Image.new("RGBA", (size,size),(0,0,0,0))
sd = ImageDraw.Draw(shadow)
sd.polygon([(x+10,y+10) for x,y in star], fill=(0,0,0,120))
shadow = shadow.filter(ImageFilter.GaussianBlur(15))
img = Image.alpha_composite(img, shadow)

img = img.convert("RGB")

Path("assets/app_icons").mkdir(parents=True, exist_ok=True)
img.save("assets/app_icons/appstore_icon.png", "PNG", optimize=True)

print("✅ Ikon laget: assets/app_icons/appstore_icon.png")
PY

echo "==> Oppdaterer pubspec.yaml"

cp pubspec.yaml pubspec.yaml.bak_722

sed -i '' '/flutter_launcher_icons:/,/^$/d' pubspec.yaml || true

cat >> pubspec.yaml <<'YAML'

dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/app_icons/appstore_icon.png
  remove_alpha_ios: true
YAML

echo "==> Installerer pakker"
flutter pub get

echo "==> Genererer ikon riktig"
dart run flutter_launcher_icons

echo "==> Rydder cache"
flutter clean

echo "==> Installerer på nytt"
flutter pub get

echo
echo "✅ FERDIG"
echo
echo "Gjør nå dette:"
echo "1) SLETT appen fra iPhone"
echo "2) flutter run -d 00008110-001138643E60401E"
echo "3) sjekk ikon"
echo "4) bygg ny iOS build"
echo "5) last opp til App Store Connect"
