#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_744_fix_xcconfig_include_paths_project_relative"

mkdir -p ios/Flutter

cp -f ios/Flutter/Debug.xcconfig "ios/Flutter/Debug.xcconfig.bak_744_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Release.xcconfig "ios/Flutter/Release.xcconfig.bak_744_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Profile.xcconfig "ios/Flutter/Profile.xcconfig.bak_744_$(date +%Y%m%d_%H%M%S)" || true

echo "==> Verifiserer Generated.xcconfig finnes"
if [ ! -f ios/Flutter/Generated.xcconfig ]; then
  echo "❌ Mangler ios/Flutter/Generated.xcconfig"
  echo "Kjør først:"
  echo "  flutter pub get"
  echo "  flutter build ios --debug --no-codesign"
  exit 1
fi

echo "==> Skriver xcconfig-filer med project-relative includes"
cat > ios/Flutter/Debug.xcconfig <<'XCCONFIG'
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Flutter/Generated.xcconfig"
XCCONFIG

cat > ios/Flutter/Release.xcconfig <<'XCCONFIG'
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Flutter/Generated.xcconfig"
XCCONFIG

cat > ios/Flutter/Profile.xcconfig <<'XCCONFIG'
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
#include "Flutter/Generated.xcconfig"
XCCONFIG

echo "==> Rydder cache"
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true
rm -rf ios/Runner.xcworkspace/xcuserdata || true
rm -rf ios/Runner.xcodeproj/xcuserdata || true

echo
echo "==> Nye filer"
echo "--- Debug.xcconfig ---"
cat ios/Flutter/Debug.xcconfig
echo
echo "--- Release.xcconfig ---"
cat ios/Flutter/Release.xcconfig
echo
echo "--- Profile.xcconfig ---"
cat ios/Flutter/Profile.xcconfig

echo
echo "✅ Ferdig"
echo "Gjør nå nøyaktig dette:"
echo "1) lukk Xcode helt"
echo "2) open ios/Runner.xcworkspace"
echo "3) Product > Clean Build Folder"
echo "4) bygg i Xcode"
echo "5) hvis build går, kjør flutter run -d 00008110-001138643E60401E"
