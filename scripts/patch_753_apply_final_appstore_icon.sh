#!/usr/bin/env bash
set -e

echo "==> FINAL APP STORE ICON"

SOURCE="$HOME/Downloads/bonusvarsel_final.png"
TARGET="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SOURCE" ]; then
  echo "❌ Legg bildet her først:"
  echo "   $SOURCE"
  exit 1
fi

echo "==> Kopierer master"
cp "$SOURCE" "$TARGET/Icon-App-1024x1024@1x.png"

echo "==> Genererer størrelser"

sizes=(20 29 40 60 76 83.5 1024)

for size in "${sizes[@]}"; do
  px=$(printf "%.0f" "$(echo "$size * 2" | bc)")
  sips -z $px $px "$SOURCE" --out "$TARGET/Icon-${px}.png" >/dev/null || true
done

echo "✅ IKON OPPDATERT"
