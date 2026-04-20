#!/usr/bin/env bash
set -euo pipefail

echo "==> Bonusvarsel iOS build repair"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"

if [ ! -d "$IOS_DIR" ]; then
  echo "Feil: Fant ikke ios/-mappen. Kjør scriptet fra Flutter-prosjektet."
  exit 1
fi

cd "$PROJECT_ROOT"

echo "==> Flutter info"
flutter --version

echo "==> Sørger for iOS artifacts"
flutter precache --ios

echo "==> Rydder Flutter"
flutter clean

echo "==> Henter dependencies"
flutter pub get

echo "==> Sletter iOS generated/pods-filer"
rm -rf "$IOS_DIR/Pods"
rm -rf "$IOS_DIR/.symlinks"
rm -rf "$IOS_DIR/Flutter/Flutter.framework"
rm -rf "$IOS_DIR/Flutter/Flutter.podspec"
rm -f  "$IOS_DIR/Podfile.lock"

# Flutter regenerate av xcconfig skjer via flutter pub get / build
# Men vi rydder også gamle xcconfig-filer som ofte skaper mismatch
rm -f "$IOS_DIR/Flutter/Generated.xcconfig"
rm -f "$IOS_DIR/Flutter/flutter_export_environment.sh"

echo "==> Regenererer Flutter iOS config"
flutter pub get

cd "$IOS_DIR"

if ! command -v pod >/dev/null 2>&1; then
  echo "Feil: CocoaPods er ikke installert."
  echo "Installer med: sudo gem install cocoapods"
  exit 1
fi

echo "==> CocoaPods cleanup"
pod deintegrate || true
pod cache clean --all || true

echo "==> Oppdaterer pod specs"
pod repo update

echo "==> Installerer pods"
pod install --repo-update

cd "$PROJECT_ROOT"

echo "==> Verifiserer Flutter build (simulator, uten codesign)"
flutter build ios --simulator --debug --no-codesign

echo ""
echo "Ferdig."
echo "Åpne alltid: ios/Runner.xcworkspace"
echo "Ikke åpne: ios/Runner.xcodeproj"
