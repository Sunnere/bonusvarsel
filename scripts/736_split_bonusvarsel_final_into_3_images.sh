#!/usr/bin/env bash
set -euo pipefail

echo "==> 736_split_bonusvarsel_final_into_3_images"

SRC="$HOME/Downloads/bonusvarsel_final.png"
DEST="assets/images/travel"

mkdir -p "$DEST"

if [ ! -f "$SRC" ]; then
  echo "❌ Fant ikke bilde:"
  echo "   $SRC"
  exit 1
fi

echo "Bruker kildefil:"
echo "  $SRC"

WIDTH=$(sips -g pixelWidth "$SRC" | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$SRC" | awk '/pixelHeight/ {print $2}')

if [ -z "${WIDTH:-}" ] || [ -z "${HEIGHT:-}" ]; then
  echo "❌ Klarte ikke lese bildestørrelse"
  exit 1
fi

PART_HEIGHT=$((HEIGHT / 3))
OFFSET_1=$PART_HEIGHT
OFFSET_2=$((PART_HEIGHT * 2))

echo "Bildestørrelse: ${WIDTH}x${HEIGHT}"
echo "Deler i tre høydebiter á ${PART_HEIGHT}px"

sips -c "$PART_HEIGHT" "$WIDTH" "$SRC" --cropOffset 0 0 --out "$DEST/hero_winter.jpg" >/dev/null
sips -c "$PART_HEIGHT" "$WIDTH" "$SRC" --cropOffset "$OFFSET_1" 0 --out "$DEST/need_luggage.jpg" >/dev/null
sips -c "$PART_HEIGHT" "$WIDTH" "$SRC" --cropOffset "$OFFSET_2" 0 --out "$DEST/hero_beach.jpg" >/dev/null

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
echo "✅ Laget:"
echo "  $DEST/hero_winter.jpg"
echo "  $DEST/need_luggage.jpg"
echo "  $DEST/hero_beach.jpg"
echo
echo "Kjør nå:"
echo "  flutter pub get"
echo "  flutter run -d macos"
