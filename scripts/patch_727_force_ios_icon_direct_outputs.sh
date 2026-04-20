#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
SRC_ICON="$ROOT_DIR/assets/app_icons/source_icon.png"
BACKUP_DIR="$IOS_DIR.bak_727_$(date +%Y%m%d_%H%M%S)"

echo "==> Starter patch_727_force_ios_icon_direct_outputs"

if [ ! -d "$IOS_DIR" ]; then
  echo "❌ Fant ikke iOS appicon-mappen: $IOS_DIR"
  exit 1
fi

mkdir -p "$ROOT_DIR/assets/app_icons"

if [ ! -f "$SRC_ICON" ]; then
  echo "❌ Fant ikke source icon: $SRC_ICON"
  echo "Legg inn en 1024x1024 PNG her først:"
  echo "  assets/app_icons/source_icon.png"
  exit 1
fi

echo "==> Tar backup"
cp -R "$IOS_DIR" "$BACKUP_DIR"
echo "✅ Backup laget: $BACKUP_DIR"

echo "==> Verifiserer source icon"
file "$SRC_ICON" || true

echo "==> Sletter gamle genererte ikonfiler"
find "$IOS_DIR" -maxdepth 1 -type f -name 'Icon-App-*.png' -delete

generate_icon() {
  local size="$1"
  local filename="$2"
  local rounded
  rounded="$(printf "%.0f" "$size")"

  echo "  -> Lager $filename (${rounded}x${rounded})"
  sips -z "$rounded" "$rounded" "$SRC_ICON" --out "$IOS_DIR/$filename" >/dev/null
}

echo "==> Lager nye iOS ikonfiler"
generate_icon 20 "Icon-App-20x20@1x.png"
generate_icon 40 "Icon-App-20x20@2x.png"
generate_icon 60 "Icon-App-20x20@3x.png"

generate_icon 29 "Icon-App-29x29@1x.png"
generate_icon 58 "Icon-App-29x29@2x.png"
generate_icon 87 "Icon-App-29x29@3x.png"

generate_icon 40 "Icon-App-40x40@1x.png"
generate_icon 80 "Icon-App-40x40@2x.png"
generate_icon 120 "Icon-App-40x40@3x.png"

generate_icon 120 "Icon-App-60x60@2x.png"
generate_icon 180 "Icon-App-60x60@3x.png"

generate_icon 76 "Icon-App-76x76@1x.png"
generate_icon 152 "Icon-App-76x76@2x.png"

generate_icon 167 "Icon-App-83.5x83.5@2x.png"
generate_icon 1024 "Icon-App-1024x1024@1x.png"

echo "==> Skriver Contents.json på nytt"
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

echo "==> Verifiserer genererte filer"
missing=0
for f in \
  Icon-App-20x20@1x.png \
  Icon-App-20x20@2x.png \
  Icon-App-20x20@3x.png \
  Icon-App-29x29@1x.png \
  Icon-App-29x29@2x.png \
  Icon-App-29x29@3x.png \
  Icon-App-40x40@1x.png \
  Icon-App-40x40@2x.png \
  Icon-App-40x40@3x.png \
  Icon-App-60x60@2x.png \
  Icon-App-60x60@3x.png \
  Icon-App-76x76@1x.png \
  Icon-App-76x76@2x.png \
  Icon-App-83.5x83.5@2x.png \
  Icon-App-1024x1024@1x.png
do
  if [ ! -f "$IOS_DIR/$f" ]; then
    echo "❌ Mangler: $f"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "❌ Ikke alle ikonfiler ble laget."
  exit 1
fi

echo "==> Rydder cache"
flutter clean >/dev/null 2>&1 || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "✅ Ferdig."
echo "Kjør nå:"
echo "  flutter pub get"
echo "  flutter run -d 00008110-001138643E60401E"
echo
echo "Hvis gammel ikon fortsatt vises på iPhone:"
echo "  1) Slett appen fra iPhone"
echo "  2) Restart iPhone"
echo "  3) Kjør flutter run på nytt"
