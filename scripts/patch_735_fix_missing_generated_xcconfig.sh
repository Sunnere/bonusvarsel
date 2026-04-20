#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_735_fix_missing_generated_xcconfig"
echo "==> Repo: $ROOT"

if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Fant ikke pubspec.yaml. Kjør scriptet fra bonusvarsel-repoet."
  exit 1
fi

echo
echo "==> Flutter version"
flutter --version || true

echo
echo "==> Sørger for at ios/Flutter finnes"
mkdir -p ios/Flutter

echo
echo "==> Kjører flutter pub get"
flutter pub get

echo
echo "==> Kjører flutter precache --ios"
flutter precache --ios

echo
echo "==> Regenererer iOS Flutter-filer"
flutter build ios --debug --no-codesign

echo
echo "==> Sjekker Generated.xcconfig"
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "✅ Fant ios/Flutter/Generated.xcconfig"
else
  echo "❌ Mangler fortsatt ios/Flutter/Generated.xcconfig"
  exit 1
fi

echo
echo "==> Sjekker Flutter xcconfig-filer"
ls -la ios/Flutter || true

echo
echo "==> Pod install"
cd ios
pod install
cd ..

echo
echo "==> Ferdig"
echo "Gjør nå:"
echo "1) lukk Xcode helt"
echo "2) åpne på nytt med: open ios/Runner.xcworkspace"
echo "3) Product > Clean Build Folder"
echo "4) prøv build igjen"
