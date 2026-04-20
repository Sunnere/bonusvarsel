#!/usr/bin/env bash
set -euo pipefail

ICON="assets/app_icons/appstore_icon.png"

mkdir -p assets/app_icons

echo "👉 Legg ønsket ikon (1024x1024 PNG) her:"
echo "   $ICON"
echo "   (Bruk ett av ikonene du sendte)"

read -p "Trykk ENTER når filen er lagt inn..."

if [ ! -f "$ICON" ]; then
  echo "❌ Fant ikke $ICON"
  exit 1
fi

cp pubspec.yaml pubspec.yaml.bak_721

# Fjern gammel config hvis finnes
sed -i '' '/flutter_launcher_icons:/,/^$/d' pubspec.yaml || true

# Legg inn ren config
cat >> pubspec.yaml <<'YAML'

dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/app_icons/appstore_icon.png
  remove_alpha_ios: true
YAML

echo "✅ pubspec oppdatert"

echo "==> flutter pub get"
flutter pub get

echo "==> Genererer ikon korrekt"
dart run flutter_launcher_icons

echo "==> Rydder cache"
flutter clean

echo "==> Installerer på nytt"
flutter pub get

echo
echo "✅ Ferdig."
echo
echo "Nå gjør du:"
echo "1) SLETT appen fra iPhone"
echo "2) flutter run -d 00008110-001138643E60401E"
echo "3) sjekk ikon"
