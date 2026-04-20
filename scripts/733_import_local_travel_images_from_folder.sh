#!/usr/bin/env bash
set -euo pipefail

echo "==> 733_import_local_travel_images_from_folder"

SRC_DIR="${1:-$HOME/Desktop/bonusvarsel_master}"
DEST_DIR="assets/images/travel"

mkdir -p "$DEST_DIR"

cat <<MSG
Forventet kildemappe:
  $SRC_DIR

Eksporter bildene fra albumet ditt til denne mappen med disse filnavnene:
  hero_beach.jpg
  hero_winter.jpg
  hero_city.jpg
  need_luggage.jpg
  need_passport.jpg
  need_powerbank.jpg
  need_kids.jpg
  need_sunscreen.jpg
  need_swimwear.jpg
  need_snorkel.jpg
  need_winter.jpg
  need_shoes.jpg
  need_sport.jpg
  need_generic.jpg
MSG

if [ ! -d "$SRC_DIR" ]; then
  echo
  echo "❌ Fant ikke kildemappen:"
  echo "   $SRC_DIR"
  echo
  echo "Gjør dette først:"
  echo "1. Eksporter bildene fra albumet til en mappe, f.eks:"
  echo "   $HOME/Desktop/bonusvarsel_master"
  echo "2. Gi dem filnavnene over"
  echo "3. Kjør scriptet igjen"
  exit 1
fi

copy_if_exists() {
  local name="$1"
  if [ -f "$SRC_DIR/$name" ]; then
    cp "$SRC_DIR/$name" "$DEST_DIR/$name"
    echo "✅ Kopierte $name"
  else
    echo "⚠️ Mangler $name"
  fi
}

copy_if_exists "hero_beach.jpg"
copy_if_exists "hero_winter.jpg"
copy_if_exists "hero_city.jpg"
copy_if_exists "need_luggage.jpg"
copy_if_exists "need_passport.jpg"
copy_if_exists "need_powerbank.jpg"
copy_if_exists "need_kids.jpg"
copy_if_exists "need_sunscreen.jpg"
copy_if_exists "need_swimwear.jpg"
copy_if_exists "need_snorkel.jpg"
copy_if_exists "need_winter.jpg"
copy_if_exists "need_shoes.jpg"
copy_if_exists "need_sport.jpg"
copy_if_exists "need_generic.jpg"

if ! grep -q "assets/images/travel/" pubspec.yaml; then
  python3 <<'PY'
from pathlib import Path
import re

p = Path("pubspec.yaml")
text = p.read_text()

if "assets/images/travel/" in text:
    raise SystemExit(0)

if re.search(r"(?m)^flutter:\s*$", text):
    if re.search(r"(?m)^  assets:\s*$", text):
        text = re.sub(r"(?m)^  assets:\s*$", "  assets:\n    - assets/images/travel/\n", text, count=1)
    else:
        text = re.sub(r"(?m)^flutter:\s*$", "flutter:\n  assets:\n    - assets/images/travel/\n", text, count=1)
    p.write_text(text)
    print("✅ Oppdaterte pubspec.yaml")
else:
    print("⚠️ Fant ikke flutter:-seksjon i pubspec.yaml")
PY
else
  echo "✅ pubspec.yaml har allerede assets/images/travel/"
fi

echo
echo "Filer i assets/images/travel:"
ls -1 "$DEST_DIR" || true
echo
echo "Kjør nå:"
echo "  flutter pub get"
echo "  flutter run -d macos"
