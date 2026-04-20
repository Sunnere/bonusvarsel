#!/bin/bash
set -e

echo "==> 734_split_master_into_travel_images"

SRC="$HOME/Downloads/bonusvarsel_master.png"
DEST="assets/images/travel"

mkdir -p "$DEST"

if [ ! -f "$SRC" ]; then
  echo "❌ Fant ikke bilde:"
  echo "$SRC"
  exit 1
fi

echo "Splitter bilde..."

# Hent dimensjoner
WIDTH=$(sips -g pixelWidth "$SRC" | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$SRC" | awk '/pixelHeight/ {print $2}')

PART_HEIGHT=$((HEIGHT / 3))

# --- TOP (winter) ---
sips -c $PART_HEIGHT $WIDTH "$SRC" --cropOffset 0 0 --out "$DEST/hero_winter.jpg" >/dev/null

# --- MIDDLE (luggage) ---
sips -c $PART_HEIGHT $WIDTH "$SRC" --cropOffset $PART_HEIGHT 0 --out "$DEST/need_luggage.jpg" >/dev/null

# --- BOTTOM (beach) ---
OFFSET=$((PART_HEIGHT * 2))
sips -c $PART_HEIGHT $WIDTH "$SRC" --cropOffset $OFFSET 0 --out "$DEST/hero_beach.jpg" >/dev/null

echo "✅ Laget:"
ls -1 "$DEST"

# --- PUBSPEC FIX ---
if ! grep -q "assets/images/travel/" pubspec.yaml; then
  echo "Oppdaterer pubspec.yaml"
  awk '
  /flutter:/ {
    print;
    print "  assets:";
    print "    - assets/images/travel/";
    next
  }
  { print }
  ' pubspec.yaml > pubspec.yaml.tmp && mv pubspec.yaml.tmp pubspec.yaml
fi

echo
echo "🚀 Kjør nå:"
echo "flutter pub get"
echo "flutter run -d macos"

