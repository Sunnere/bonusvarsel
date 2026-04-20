#!/usr/bin/env bash
set -euo pipefail

IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
SRC_DIR="assets/app_icons"
SRC_ICON="$SRC_DIR/source_icon.png"

if [ ! -d "$IOS_DIR" ]; then
  echo "❌ Fant ikke $IOS_DIR"
  exit 1
fi

mkdir -p "$SRC_DIR"
cp -R "$IOS_DIR" "${IOS_DIR}.bak_726_$(date +%s)"
echo "✅ Backup laget"

echo "==> Lager source_icon.png"
python3 - <<'PY'
import base64
from pathlib import Path

b64 = """
iVBORw0KGgoAAAANSUhEUgAABAAAAAQACAIAAADwf7zUAACetklEQVR42u3967M9S37Xd2Zu9GCEhMDW6XOT0A2p1QbLgzGMAeEZjxUxYWiP7urWBQkBg42fzp8yT2YiCN3RpVsSxhOWnkwEwxiEuRgzluSR1BIXg/qc7tOaCQeBZPxk5zzYe69dVatqrbpkVmVVvd69dSb8Zr73Od/7+6f7+f8HAAAgwX7P+T8AAAB4nQAAAP4PAACA1wkAAOB1AgAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAADgdQIAAHidAAAAeJ0AAABeJwAAgNcJAAAgnv8H1j8xLwAA
""".strip().replace("\n", "")

out = Path("assets/app_icons/source_icon.png")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(base64.b64decode(b64))
print(f"✅ Skrev {out}")
PY

echo "==> Verifiserer source icon"
file "$SRC_ICON"

echo "==> Sletter gamle ikonfiler"
rm -f "$IOS_DIR"/*.png

echo "==> Lager nye iOS ikonfiler med sips"
make_icon () {
  local src="$1"
  local dst="$2"
  local px="$3"
  sips -s format png -z "$px" "$px" "$src" --out "$dst" >/dev/null
}

make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-20x20@1x.png" 20
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-20x20@2x.png" 40
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-20x20@3x.png" 60
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-29x29@1x.png" 29
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-29x29@2x.png" 58
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-29x29@3x.png" 87
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-40x40@1x.png" 40
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-40x40@2x.png" 80
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-40x40@3x.png" 120
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-60x60@2x.png" 120
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-60x60@3x.png" 180
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-76x76@1x.png" 76
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-76x76@2x.png" 152
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-83.5x83.5@2x.png" 167
make_icon "$SRC_ICON" "$IOS_DIR/Icon-App-1024x1024@1x.png" 1024

echo "==> Skriver ny Contents.json"
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

echo "==> Rydder cache"
flutter clean >/dev/null 2>&1 || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "==> Nye tidsstempler"
ls -la "$IOS_DIR"

echo
echo "✅ Ferdig."
echo "Gjør nå:"
echo "1) SLETT appen fra iPhone"
echo "2) restart iPhone"
echo "3) flutter pub get"
echo "4) flutter run -d 00008110-001138643E60401E"
