#!/usr/bin/env bash
set -euo pipefail

echo "==> 740_find_and_import_travel_images_folder"

DEST_DIR="assets/images/travel"
mkdir -p "$DEST_DIR"

SEARCH_ROOTS=(
  "$HOME/Desktop"
  "$HOME/Downloads"
  "$HOME/Documents"
  "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Desktop"
  "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents"
)

FOUND_DIR=""

for root in "${SEARCH_ROOTS[@]}"; do
  [ -d "$root" ] || continue

  candidate="$(find "$root" -maxdepth 4 -type d \( -iname "*bonusvarsel*travel*images*" -o -iname "*travel*images*" \) 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    FOUND_DIR="$candidate"
    break
  fi
done

if [ -z "$FOUND_DIR" ]; then
  echo "❌ Fant ingen mappe som ligner på bonusvarsel_travel_images."
  echo
  echo "Kjør denne for å finne den manuelt:"
  echo '  find "$HOME" -type d \( -iname "*bonusvarsel*travel*images*" -o -iname "*travel*images*" \) 2>/dev/null | head -50'
  exit 1
fi

echo "Fant mappe:"
echo "  $FOUND_DIR"

echo
echo "Innhold:"
ls -la "$FOUND_DIR"

echo
for f in beach.jpg luggage.jpg winter.jpg; do
  if [ ! -f "$FOUND_DIR/$f" ]; then
    echo "❌ Mangler fil:"
    echo "   $FOUND_DIR/$f"
    echo
    echo "Mappen må inneholde:"
    echo "  beach.jpg"
    echo "  luggage.jpg"
    echo "  winter.jpg"
    exit 1
  fi
done

cp "$FOUND_DIR/beach.jpg"   "$DEST_DIR/hero_beach.jpg"
cp "$FOUND_DIR/luggage.jpg" "$DEST_DIR/need_luggage.jpg"
cp "$FOUND_DIR/winter.jpg"  "$DEST_DIR/hero_winter.jpg"

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
