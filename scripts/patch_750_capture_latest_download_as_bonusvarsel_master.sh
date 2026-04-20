#!/usr/bin/env bash
set -euo pipefail

echo "==> patch_750_capture_latest_download_as_bonusvarsel_master"

LATEST="$(
  find "$HOME/Downloads" -maxdepth 1 -type f \
    \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) \
    -print0 | xargs -0 ls -t 2>/dev/null | head -1
)"

if [ -z "${LATEST:-}" ]; then
  echo "❌ Fant ingen bilde-filer i Downloads"
  echo "Lagre bildet fra chat først, og kjør scriptet igjen."
  exit 1
fi

TARGET="$HOME/Downloads/bonusvarsel_master.png"

echo "==> Fant nyeste bilde:"
echo "   $LATEST"

cp "$LATEST" "$TARGET"

echo "==> Kopierte til:"
echo "   $TARGET"

echo
echo "==> Verifiserer"
file "$TARGET" || true
ls -lh "$TARGET" || true

echo
echo "==> Åpner filen så du kan sjekke at det er riktig ikon"
open "$TARGET"

echo
echo "✅ Hvis bildet som åpnet er riktig, kjør nå:"
echo "bash scripts/patch_749_use_exact_master_from_downloads.sh"
echo
echo "❌ Hvis bildet som åpnet er feil, slett bonusvarsel_master.png,"
echo "lagre riktig bilde fra chat, og kjør dette scriptet igjen."
