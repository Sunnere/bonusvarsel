#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_745_fix_podfile_and_flutter_xcconfig_warnings"

if [ ! -f ios/Podfile ]; then
  echo "❌ Fant ikke ios/Podfile"
  exit 1
fi

mkdir -p ios/Flutter

cp -f ios/Podfile "ios/Podfile.bak_745_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Debug.xcconfig "ios/Flutter/Debug.xcconfig.bak_745_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Release.xcconfig "ios/Flutter/Release.xcconfig.bak_745_$(date +%Y%m%d_%H%M%S)" || true
cp -f ios/Flutter/Profile.xcconfig "ios/Flutter/Profile.xcconfig.bak_745_$(date +%Y%m%d_%H%M%S)" || true

echo "==> Setter platform :ios, '13.0' i Podfile"
python3 <<'PY'
from pathlib import Path
import re

p = Path("ios/Podfile")
text = p.read_text()

if "platform :ios" not in text:
    text = "platform :ios, '13.0'\n\n" + text
else:
    text = re.sub(
        r"platform\s*:ios\s*,\s*['\"][^'\"]+['\"]",
        "platform :ios, '13.0'",
        text,
        count=1,
    )

p.write_text(text)
print("✅ Podfile oppdatert")
PY

echo "==> Skriver Flutter xcconfig-filer med riktige project-relative includes"
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

echo "==> Verifiserer Generated.xcconfig"
if [ ! -f ios/Flutter/Generated.xcconfig ]; then
  echo "❌ ios/Flutter/Generated.xcconfig mangler"
  echo "Kjør:"
  echo "  flutter pub get"
  echo "  flutter build ios --debug --no-codesign"
  exit 1
fi

echo "==> Kjør flutter pub get"
flutter pub get

echo "==> Kjør pod install på nytt"
cd ios
pod install
cd ..

echo
echo "==> Ferdig"
echo "--- Podfile head ---"
sed -n '1,20p' ios/Podfile
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
echo "Neste steg:"
echo "1) lukk Xcode helt"
echo "2) open ios/Runner.xcworkspace"
echo "3) Product > Clean Build Folder"
echo "4) prøv Run igjen"
