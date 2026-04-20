#!/usr/bin/env bash
set -e

echo "==> patch_752_optimize_and_lock_master_icon"

SOURCE="$HOME/Downloads/bonusvarsel_master.png"
TARGET_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
MASTER_LOCK="assets/icon_master_locked.png"

if [ ! -f "$SOURCE" ]; then
  echo "❌ Fant ikke masterfil:"
  echo "   $SOURCE"
  exit 1
fi

echo "==> Bruker kilde:"
echo "   $SOURCE"

mkdir -p assets

echo "==> Lager optimalisert master (1024x1024)"

# Resize til Apple-standard
sips -z 1024 1024 "$SOURCE" --out assets/icon_master_locked.png >/dev/null

# Fjern metadata (ren fil)
xattr -c assets/icon_master_locked.png || true

echo "==> Kopierer til AppIcon-set"

cp assets/icon_master_locked.png "$TARGET_DIR/Icon-App-1024x1024@1x.png"

echo "==> Genererer alle nødvendige størrelser"

sizes=(
  20 29 40 60 76 83.5 1024
)

for size in "${sizes[@]}"; do
  px=$(printf "%.0f" "$(echo "$size * 2" | bc)")
  sips -z $px $px assets/icon_master_locked.png --out "$TARGET_DIR/Icon-${px}.png" >/dev/null || true
done

echo "==> Ferdig"
echo "MASTER ER NÅ LÅST:"
echo "assets/icon_master_locked.png"

