#!/usr/bin/env bash
set -euo pipefail

echo "==> 735_find_and_split_master_image"

DEST="assets/images/travel"
mkdir -p "$DEST"

echo "Søker i ~/Downloads etter filer som ligner på bonusvarsel_master ..."
mapfile -t MATCHES < <(
  find "$HOME/Downloads" -type f \
    \( -iname "*bonusvarsel*master*.png" -o -iname "*bonusvarsel*master*.jpg" -o -iname "*bonusvarsel*master*.jpeg" -o -iname "*bonusvarsel*master*.heic" -o -iname "*bonusvarsel*.png" -o -iname "*bonusvarsel*.jpg" -o -iname "*bonusvarsel*.jpeg" -o -iname "*bonusvarsel*.heic" \) \
    | sort
)

if [ "${#MATCHES[@]}" -eq 0 ]; then
  echo "❌ Fant ingen filer i ~/Downloads som ligner på bonusvarsel_master"
  echo
  echo "Kjør denne for å se mulige filer manuelt:"
  echo "  find ~/Downloads -type f | grep -i bonusvarsel"
  exit 1
fi

echo "Treff:"
for i in "${!MATCHES[@]}"; do
  printf "  [%s] %s\n" "$i" "${MATCHES[$i]}"
done
echo

SRC="${MATCHES[0]}"
echo "Bruker første treff:"
echo "  $SRC"

EXT="${SRC##*.}"
EXT_LOWER="$(printf '%s' "$EXT" | tr '[:upper:]' '[:lower:]')"

WORK_SRC="$SRC"

# Konverter HEIC til PNG hvis nødvendig
if [ "$EXT_LOWER" = "heic" ]; then
  echo "Konverterer HEIC til PNG ..."
  WORK_SRC="$DEST/_master_converted.png"
  sips -s format png "$SRC" --out "$WORK_SRC" >/dev/null
fi

echo "Leser bildestørrelse ..."
WIDTH=$(sips -g pixelWidth "$WORK_SRC" | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$WORK_SRC" | awk '/pixelHeight/ {print $2}')

if [ -z "${WIDTH:-}" ] || [ -z "${HEIGHT:-}" ]; then
  echo "❌ Klarte ikke lese bildestørrelse"
  exit 1
fi

PART_HEIGHT=$((HEIGHT / 3))
OFFSET2=$((PART_HEIGHT * 2))

echo "Splitter i 3 deler ..."
sips -c "$PART_HEIGHT" "$WIDTH" "$WORK_SRC" --cropOffset 0 0 --out "$DEST/hero_winter.jpg" >/dev/null
sips -c "$PART_HEIGHT" "$WIDTH" "$WORK_SRC" --cropOffset "$PART_HEIGHT" 0 --out "$DEST/need_luggage.jpg" >/dev/null
sips -c "$PART_HEIGHT" "$WIDTH" "$WORK_SRC" --cropOffset "$OFFSET2" 0 --out "$DEST/hero_beach.jpg" >/dev/null

if ! grep -q "assets/images/travel/" pubspec.yaml; then
  echo "Oppdaterer pubspec.yaml ..."
  python3 <<'PY'
from pathlib import Path
import re
p = Path("pubspec.yaml")
text = p.read_text()

if "assets/images/travel/" not in text:
    if re.search(r"(?m)^flutter:\s*$", text):
        if re.search(r"(?m)^  assets:\s*$", text):
            text = re.sub(r"(?m)^  assets:\s*$", "  assets:\n    - assets/images/travel/\n", text, count=1)
        else:
            text = re.sub(r"(?m)^flutter:\s*$", "flutter:\n  assets:\n    - assets/images/travel/\n", text, count=1)
        p.write_text(text)
        print("✅ pubspec.yaml oppdatert")
    else:
        print("⚠️ Fant ikke flutter:-seksjon")
PY
fi

echo
echo "✅ Laget filer:"
ls -1 "$DEST" | sed 's/^/  - /'
echo
echo "Kjør nå:"
echo "  flutter pub get"
echo "  flutter run -d macos"
