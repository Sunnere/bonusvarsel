#!/usr/bin/env bash
set -euo pipefail

echo "==> 742_import_desktop_named_travel_images"

DEST_DIR="assets/images/travel"
mkdir -p "$DEST_DIR"

SRC_WINTER="$HOME/Desktop/assets:images:travel:hero_winter.jpg  (ski).png"
SRC_BEACH="$HOME/Desktop/assets:images:travel:hero_beach.jpg   (strand).png"
SRC_LUGGAGE="$HOME/Desktop/assets:images:travel:need_luggage.jpg (flyplass:koffert).png"

for f in "$SRC_WINTER" "$SRC_BEACH" "$SRC_LUGGAGE"; do
  if [ ! -f "$f" ]; then
    echo "❌ Fant ikke fil:"
    echo "   $f"
    exit 1
  fi
done

echo "Kopierer og konverterer bilder ..."

sips -s format jpeg "$SRC_WINTER" --out "$DEST_DIR/hero_winter.jpg" >/dev/null
sips -s format jpeg "$SRC_BEACH" --out "$DEST_DIR/hero_beach.jpg" >/dev/null
sips -s format jpeg "$SRC_LUGGAGE" --out "$DEST_DIR/need_luggage.jpg" >/dev/null

# fallback-filer så travel_page ikke mangler bilder
cp "$DEST_DIR/hero_beach.jpg"   "$DEST_DIR/hero_city.jpg"
cp "$DEST_DIR/need_luggage.jpg" "$DEST_DIR/need_generic.jpg"
cp "$DEST_DIR/need_luggage.jpg" "$DEST_DIR/need_passport.jpg"
cp "$DEST_DIR/need_luggage.jpg" "$DEST_DIR/need_powerbank.jpg"
cp "$DEST_DIR/need_luggage.jpg" "$DEST_DIR/need_kids.jpg"
cp "$DEST_DIR/hero_beach.jpg"   "$DEST_DIR/need_sunscreen.jpg"
cp "$DEST_DIR/hero_beach.jpg"   "$DEST_DIR/need_swimwear.jpg"
cp "$DEST_DIR/hero_beach.jpg"   "$DEST_DIR/need_snorkel.jpg"
cp "$DEST_DIR/hero_winter.jpg"  "$DEST_DIR/need_winter.jpg"
cp "$DEST_DIR/need_luggage.jpg" "$DEST_DIR/need_shoes.jpg"
cp "$DEST_DIR/need_luggage.jpg" "$DEST_DIR/need_sport.jpg"

python3 <<'PY'
from pathlib import Path
import re

p = Path("pubspec.yaml")
if not p.exists():
    print("⚠️ Fant ikke pubspec.yaml")
    raise SystemExit(0)

text = p.read_text()

if "assets/images/travel/" not in text:
    if re.search(r"(?m)^flutter:\s*$", text):
        if re.search(r"(?m)^  assets:\s*$", text):
            text = re.sub(
                r"(?m)^  assets:\s*$",
                "  assets:\n    - assets/images/travel/\n",
                text,
                count=1,
            )
        else:
            text = re.sub(
                r"(?m)^flutter:\s*$",
                "flutter:\n  assets:\n    - assets/images/travel/\n",
                text,
                count=1,
            )
        p.write_text(text)
        print("✅ Oppdaterte pubspec.yaml")
    else:
        print("⚠️ Fant ikke flutter:-seksjon i pubspec.yaml")
else:
    print("✅ pubspec.yaml har allerede assets/images/travel/")
PY

echo
echo "✅ Importert bilder:"
ls -1 "$DEST_DIR" | sed 's/^/  - /'
echo
echo "Kjør nå:"
echo "  flutter pub get"
echo "  flutter run -d macos"
