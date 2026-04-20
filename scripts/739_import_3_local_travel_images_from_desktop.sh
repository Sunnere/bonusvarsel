#!/usr/bin/env bash
set -euo pipefail

echo "==> 739_import_3_local_travel_images_from_desktop"

SRC_DIR="$HOME/Desktop/bonusvarsel_travel_images"
DEST_DIR="assets/images/travel"

mkdir -p "$DEST_DIR"

echo "Bruker kildemappe:"
echo "  $SRC_DIR"

if [ ! -d "$SRC_DIR" ]; then
  echo "❌ Fant ikke mappen:"
  echo "   $SRC_DIR"
  exit 1
fi

for f in beach.jpg luggage.jpg winter.jpg; do
  if [ ! -f "$SRC_DIR/$f" ]; then
    echo "❌ Mangler fil:"
    echo "   $SRC_DIR/$f"
    echo
    echo "Mappen må inneholde disse tre filene:"
    echo "  beach.jpg"
    echo "  luggage.jpg"
    echo "  winter.jpg"
    exit 1
  fi
done

echo "Kopierer bilder ..."

cp "$SRC_DIR/beach.jpg"   "$DEST_DIR/hero_beach.jpg"
cp "$SRC_DIR/luggage.jpg" "$DEST_DIR/need_luggage.jpg"
cp "$SRC_DIR/winter.jpg"  "$DEST_DIR/hero_winter.jpg"

# fallback-filer så travel_page ikke mangler assets
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
echo "✅ Importert bilder til:"
echo "  $DEST_DIR"
echo
ls -1 "$DEST_DIR" | sed 's/^/  - /'
echo
echo "Kjør nå:"
echo "  flutter pub get"
echo "  flutter run -d macos"
