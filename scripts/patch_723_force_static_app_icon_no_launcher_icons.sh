#!/usr/bin/env bash
set -euo pipefail

SRC="assets/app_icons/source_icon.png"
IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES="android/app/src/main/res"
PUBSPEC="pubspec.yaml"

if [ ! -f "$SRC" ]; then
  echo "❌ Fant ikke $SRC"
  echo "Legg blå/gull-ikonet her først: assets/app_icons/source_icon.png"
  exit 1
fi

if [ ! -d "$IOS_DIR" ]; then
  echo "❌ Fant ikke $IOS_DIR"
  exit 1
fi

if [ ! -d "$ANDROID_RES" ]; then
  echo "❌ Fant ikke $ANDROID_RES"
  exit 1
fi

cp -R "$IOS_DIR" "${IOS_DIR}.bak_723_$(date +%s)"
cp "$PUBSPEC" "${PUBSPEC}.bak_723_$(date +%s)"
echo "✅ Backup laget"

python3 - <<'PY'
from pathlib import Path
from PIL import Image
import json

src = Path("assets/app_icons/source_icon.png")
ios_dir = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
android_res = Path("android/app/src/main/res")

img = Image.open(src).convert("RGB")

# 1) Fjern gamle iOS app icon png-er
for f in ios_dir.glob("*.png"):
    f.unlink()

# 2) Skriv iOS app icons på nytt
ios_entries = [
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
for filename, px, idiom, size_str, scale in ios_entries:
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
    "info": {"version": 1, "author": "xcode"},
}
(ios_dir / "Contents.json").write_text(json.dumps(contents, indent=2))

# 3) Android launcher icons
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
    img.resize((px, px)).save(out, "PNG")

print("✅ Skrev nye iOS- og Android-ikoner direkte")
PY

# 4) Fjern flutter_launcher_icons config hvis den finnes
python3 - <<'PY'
from pathlib import Path
import re

path = Path("pubspec.yaml")
text = path.read_text()

text = re.sub(
    r'\nflutter_launcher_icons:\n(?:  .*\n)+',
    '\n',
    text,
    flags=re.MULTILINE
)
text = re.sub(
    r'\n  flutter_launcher_icons: .*\n',
    '\n',
    text,
    flags=re.MULTILINE
)

path.write_text(text)
print("✅ Fjernet flutter_launcher_icons fra pubspec hvis den fantes")
PY

echo
echo "==> flutter clean"
flutter clean || true

echo "==> rydder Xcode cache"
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze || true

echo
echo "✅ Ferdig."
echo
echo "Gjør nå dette nøyaktig:"
echo "  1) SLETT appen fra iPhone"
echo "  2) restart iPhone"
echo "  3) flutter run -d 00008110-001138643E60401E"
echo "  4) sjekk ikon på hjemskjermen"
echo
echo "Kontroll:"
echo "  ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset"
