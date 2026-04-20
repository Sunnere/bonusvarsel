#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_741_fix_podfile_and_flutter_xcconfig_warnings"

if [ ! -f "ios/Podfile" ]; then
  echo "❌ Fant ikke ios/Podfile"
  exit 1
fi

mkdir -p ios/Flutter

cp -f ios/Podfile "ios/Podfile.bak_741_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Debug.xcconfig "ios/Flutter/Debug.xcconfig.bak_741_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Release.xcconfig "ios/Flutter/Release.xcconfig.bak_741_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Profile.xcconfig "ios/Flutter/Profile.xcconfig.bak_741_$(date +%Y%m%d_%H%M%S)" || true

echo "==> Oppdaterer Podfile"
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
print("✅ Podfile satt til platform :ios, '13.0'")
PY

echo "==> Skriver Flutter xcconfig-filer med Pods includes først"
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

echo "==> Kjører flutter pub get"
flutter pub get

echo "==> Kjører pod install"
cd ios
pod install
cd ..

echo
echo "==> Ferdig"
echo "--- Podfile head ---"
sed -n '1,30p' ios/Podfile
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
echo "Neste:"
echo "1) slett appen fra iPhone"
echo "2) restart iPhone"
echo "3) open ios/Runner.xcworkspace"
echo "4) Product > Clean Build Folder"
echo "5) flutter run -d 00008110-001138643E60401E"
