#!/usr/bin/env bash
set -euo pipefail

echo "==> 737_use_uploaded_chat_images_for_travel_assets"

DEST="assets/images/travel"
mkdir -p "$DEST"

SRC_BEACH="/mnt/data/0D92E422-1702-44A1-9EA1-9F52BD9D4FC8.png"
SRC_LUGGAGE="/mnt/data/DC87E2FF-392F-4D2A-8F95-B42A1BE14FDD.png"
SRC_WINTER="/mnt/data/59724EE8-4C49-403E-AE70-5663D2D9E8F1.png"

for f in "$SRC_BEACH" "$SRC_LUGGAGE" "$SRC_WINTER"; do
  if [ ! -f "$f" ]; then
    echo "❌ Fant ikke opplastet bilde:"
    echo "   $f"
    exit 1
  fi
done

echo "Kopierer riktige chat-bilder til assets ..."

sips -s format jpeg "$SRC_BEACH" --out "$DEST/hero_beach.jpg" >/dev/null
sips -s format jpeg "$SRC_LUGGAGE" --out "$DEST/need_luggage.jpg" >/dev/null
sips -s format jpeg "$SRC_WINTER" --out "$DEST/hero_winter.jpg" >/dev/null

# Enkle fallback-filer så travel_page ikke mangler assets
cp "$DEST/hero_beach.jpg" "$DEST/hero_city.jpg"
cp "$DEST/need_luggage.jpg" "$DEST/need_generic.jpg"
cp "$DEST/need_luggage.jpg" "$DEST/need_passport.jpg"
cp "$DEST/need_luggage.jpg" "$DEST/need_powerbank.jpg"
cp "$DEST/need_luggage.jpg" "$DEST/need_kids.jpg"
cp "$DEST/hero_beach.jpg" "$DEST/need_sunscreen.jpg"
cp "$DEST/hero_beach.jpg" "$DEST/need_swimwear.jpg"
cp "$DEST/hero_beach.jpg" "$DEST/need_snorkel.jpg"
cp "$DEST/hero_winter.jpg" "$DEST/need_winter.jpg"
cp "$DEST/need_luggage.jpg" "$DEST/need_shoes.jpg"
cp "$DEST/need_luggage.jpg" "$DEST/need_sport.jpg"

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
echo "✅ Laget disse filene:"
ls -1 "$DEST" | sed 's/^/  - /'
echo
echo "Brukt mapping:"
echo "  hero_beach.jpg   <- første opplastede bilde"
echo "  need_luggage.jpg <- andre opplastede bilde"
echo "  hero_winter.jpg  <- tredje opplastede bilde"
echo
echo "Kjør nå:"
echo "  flutter pub get"
echo "  flutter run -d macos"
