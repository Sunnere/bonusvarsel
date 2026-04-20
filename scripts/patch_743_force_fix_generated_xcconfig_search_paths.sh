#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"

echo "==> patch_743_force_fix_generated_xcconfig_search_paths"

if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Fant ikke pubspec.yaml"
  exit 1
fi

if [ ! -f "$PBXPROJ" ]; then
  echo "❌ Fant ikke $PBXPROJ"
  exit 1
fi

mkdir -p ios/Flutter
mkdir -p ios/Runner

cp -f "$PBXPROJ" "$PBXPROJ.bak_743_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Debug.xcconfig "ios/Flutter/Debug.xcconfig.bak_743_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Release.xcconfig "ios/Flutter/Release.xcconfig.bak_743_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Profile.xcconfig "ios/Flutter/Profile.xcconfig.bak_743_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Podfile "ios/Podfile.bak_743_$(date +%Y%m%d_%H%M%S)" || true

echo "==> Sikrer platform i Podfile"
python3 <<'PY'
from pathlib import Path
import re

podfile = Path("ios/Podfile")
text = podfile.read_text()

if "platform :ios" not in text:
    text = "platform :ios, '13.0'\n\n" + text
else:
    text = re.sub(r"platform\s*:ios\s*,\s*['\"][^'\"]+['\"]", "platform :ios, '13.0'", text, count=1)

podfile.write_text(text)
print("✅ Podfile oppdatert")
PY

echo "==> Flutter pub get"
flutter pub get

echo "==> Flutter precache ios"
flutter precache --ios

echo "==> Regenererer Flutter iOS buildfiler"
flutter build ios --debug --no-codesign

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "❌ ios/Flutter/Generated.xcconfig ble ikke laget"
  exit 1
fi

echo "✅ Fant ios/Flutter/Generated.xcconfig"

echo "==> Skriver robuste xcconfig-filer"
cat > ios/Flutter/Debug.xcconfig <<'XCCONFIG'
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Generated.xcconfig"
XCCONFIG

cat > ios/Flutter/Release.xcconfig <<'XCCONFIG'
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Generated.xcconfig"
XCCONFIG

cat > ios/Flutter/Profile.xcconfig <<'XCCONFIG'
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
#include "Generated.xcconfig"
XCCONFIG

echo "==> Legger kopier av Generated.xcconfig i ekstra search-path steder"
cp -f ios/Flutter/Generated.xcconfig ios/Generated.xcconfig
cp -f ios/Flutter/Generated.xcconfig ios/Runner/Generated.xcconfig

echo "==> Patcher project.pbxproj til å bruke Flutter xcconfig-filer"
python3 <<'PY'
from pathlib import Path
import re

pbx = Path("ios/Runner.xcodeproj/project.pbxproj")
text = pbx.read_text()

# Normalize file reference paths if they already exist with odd formatting
text = re.sub(r'path = Flutter/Debug\.xcconfig;', 'path = Flutter/Debug.xcconfig;', text)
text = re.sub(r'path = Flutter/Release\.xcconfig;', 'path = Flutter/Release.xcconfig;', text)
text = re.sub(r'path = Flutter/Profile\.xcconfig;', 'path = Flutter/Profile.xcconfig;', text)

pbx.write_text(text)
print("✅ project.pbxproj normalisert")
PY

echo "==> Rydder Xcode workspace/cache"
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Runner.xcworkspace/xcuserdata
rm -rf ios/Runner.xcodeproj/xcuserdata
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo "==> Pod install"
cd ios
pod install
cd ..

echo
echo "==> Verifisering"
echo "--- Generated.xcconfig ---"
ls -la ios/Flutter/Generated.xcconfig
ls -la ios/Generated.xcconfig
ls -la ios/Runner/Generated.xcconfig

echo
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
echo "1) Lukk Xcode helt"
echo "2) Kjør: open ios/Runner.xcworkspace"
echo "3) I Xcode: Product > Clean Build Folder"
echo "4) Bygg i Xcode først"
echo "5) Hvis build går, kjør flutter run -d 00008110-001138643E60401E"
