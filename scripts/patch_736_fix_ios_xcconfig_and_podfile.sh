#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_736_fix_ios_xcconfig_and_podfile"
echo "==> Repo: $ROOT"

if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Fant ikke pubspec.yaml"
  exit 1
fi

if [ ! -f "ios/Podfile" ]; then
  echo "❌ Fant ikke ios/Podfile"
  exit 1
fi

mkdir -p ios/Flutter

backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    cp "$f" "$f.bak_736_$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup: $f"
  fi
}

backup_file "ios/Podfile"
backup_file "ios/Flutter/Debug.xcconfig"
backup_file "ios/Flutter/Release.xcconfig"
backup_file "ios/Flutter/Profile.xcconfig"

echo
echo "==> Sikrer platform :ios, '13.0' i Podfile"
python3 <<'PY'
from pathlib import Path
podfile = Path("ios/Podfile")
text = podfile.read_text()

if "platform :ios" not in text:
    text = "platform :ios, '13.0'\n\n" + text
    podfile.write_text(text)
    print("✅ La til platform :ios, '13.0'")
else:
    import re
    new = re.sub(r"platform\s*:ios\s*,\s*['\"][^'\"]+['\"]", "platform :ios, '13.0'", text, count=1)
    if new != text:
        podfile.write_text(new)
        print("✅ Oppdaterte eksisterende platform :ios til 13.0")
    else:
        print("ℹ️ Podfile hadde allerede platform :ios")
PY

echo
echo "==> Skriver rene Flutter xcconfig-filer"

cat > ios/Flutter/Debug.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
XCCONFIG

cat > ios/Flutter/Release.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
XCCONFIG

cat > ios/Flutter/Profile.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
XCCONFIG

echo "✅ Skrev ios/Flutter/{Debug,Release,Profile}.xcconfig"

echo
echo "==> Kjører flutter pub get"
flutter pub get

echo
echo "==> Pod install på nytt"
cd ios
pod install
cd ..

echo
echo "==> Verifiserer filer"
ls -la ios/Flutter
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
echo "Gjør nå:"
echo "1) lukk Xcode helt"
echo "2) open ios/Runner.xcworkspace"
echo "3) Product > Clean Build Folder"
echo "4) bygg i Xcode"
echo "5) hvis build går: test ikon på nytt"
