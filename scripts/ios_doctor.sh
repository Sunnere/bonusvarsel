#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"

echo "==> iOS Doctor: Bonusvarsel"
echo "Project root: $PROJECT_ROOT"

# -----------------------------
# 1. BASIC CHECKS
# -----------------------------
if [ ! -d "$IOS_DIR" ]; then
  echo "❌ ios/ mappe mangler"
  exit 1
fi

if [ ! -f "$IOS_DIR/Podfile" ]; then
  echo "❌ Podfile mangler"
  exit 1
fi

echo "==> Flutter check"
flutter --version

# -----------------------------
# 2. VALIDATE PODFILE
# -----------------------------
echo "==> Sjekker Podfile"

if ! grep -q "flutter_install_all_ios_pods" "$IOS_DIR/Podfile"; then
  echo "❌ Podfile mangler flutter_install_all_ios_pods"
  exit 1
fi

if ! grep -q "flutter_additional_ios_build_settings" "$IOS_DIR/Podfile"; then
  echo "❌ Podfile mangler flutter_additional_ios_build_settings"
  exit 1
fi

echo "✅ Podfile OK"

# -----------------------------
# 3. CLEAN EVERYTHING
# -----------------------------
echo "==> Rydder Flutter"
flutter clean

echo "==> Henter dependencies"
flutter pub get

echo "==> Sletter iOS build artifacts"
rm -rf "$IOS_DIR/Pods"
rm -rf "$IOS_DIR/.symlinks"
rm -rf "$IOS_DIR/Flutter/Flutter.framework"
rm -rf "$IOS_DIR/Flutter/Flutter.podspec"
rm -f "$IOS_DIR/Podfile.lock"

rm -f "$IOS_DIR/Flutter/Generated.xcconfig"
rm -f "$IOS_DIR/Flutter/flutter_export_environment.sh"

# -----------------------------
# 4. REGENERATE FLUTTER IOS
# -----------------------------
echo "==> Regenererer Flutter iOS config"
flutter pub get

# -----------------------------
# 5. COCOAPODS
# -----------------------------
cd "$IOS_DIR"

if ! command -v pod >/dev/null 2>&1; then
  echo "❌ CocoaPods mangler"
  exit 1
fi

echo "==> CocoaPods reset"
pod deintegrate || true
pod cache clean --all || true

echo "==> Pod install"
pod install --repo-update

cd "$PROJECT_ROOT"

# -----------------------------
# 6. DERIVED DATA CHECK
# -----------------------------
DERIVED=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED" ]; then
  echo "⚠️ DerivedData finnes (kan gi feil)"
  echo "Tips: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
fi

# -----------------------------
# 7. BUILD TEST
# -----------------------------
echo "==> Tester build"
if flutter build ios --simulator --debug --no-codesign; then
  echo "✅ BUILD OK"
else
  echo "❌ BUILD FEILET"
  echo ""
  echo "Vanlige årsaker:"
  echo "1. Åpner .xcodeproj i stedet for .xcworkspace"
  echo "2. Pod install feilet stille"
  echo "3. Flutter SDK mismatch"
  echo "4. Xcode cache (DerivedData)"
  exit 1
fi

# -----------------------------
# 8. FINAL INFO
# -----------------------------
echo ""
echo "==> Ferdig"
echo "Åpne riktig prosjekt:"
echo "open ios/Runner.xcworkspace"
echo ""
echo "Hvis fortsatt feil:"
echo "rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "kjør scriptet på nytt"
