#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_738_hard_reset_ios_flutter_configs"
echo "==> ROOT: $ROOT"

if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Fant ikke pubspec.yaml. Kjør fra bonusvarsel-repoet."
  exit 1
fi

backup_dir="ios_backup_738_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

echo "==> Tar backup av viktige iOS-filer"
[ -d ios/Flutter ] && cp -R ios/Flutter "$backup_dir/Flutter" || true
[ -f ios/Podfile ] && cp ios/Podfile "$backup_dir/Podfile" || true
[ -f ios/Podfile.lock ] && cp ios/Podfile.lock "$backup_dir/Podfile.lock" || true
echo "✅ Backup: $backup_dir"

echo
echo "==> Lukker gammel iOS-state"
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/App.framework
rm -f ios/Flutter/Generated.xcconfig
rm -f ios/Flutter/flutter_export_environment.sh
rm -rf build
rm -rf ios/build
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

mkdir -p ios/Flutter

echo
echo "==> Sørger for platform i Podfile"
python3 <<'PY'
from pathlib import Path
import re

podfile = Path("ios/Podfile")
if not podfile.exists():
    raise SystemExit("❌ ios/Podfile mangler")

text = podfile.read_text()

if "platform :ios" not in text:
    text = "platform :ios, '13.0'\n\n" + text
else:
    text = re.sub(r"platform\s*:ios\s*,\s*['\"][^'\"]+['\"]", "platform :ios, '13.0'", text, count=1)

podfile.write_text(text)
print("✅ Podfile oppdatert")
PY

echo
echo "==> Flutter pub get"
flutter pub get

echo
echo "==> Flutter precache iOS"
flutter precache --ios

echo
echo "==> Regenererer Flutter iOS config"
flutter build ios --debug --no-codesign

echo
echo "==> Verifiserer Generated.xcconfig"
if [ ! -f ios/Flutter/Generated.xcconfig ]; then
  echo "❌ ios/Flutter/Generated.xcconfig ble ikke laget"
  exit 1
fi
echo "✅ Fant ios/Flutter/Generated.xcconfig"

echo
echo "==> Skriver rene xcconfig-filer"
cat > ios/Flutter/Debug.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
XCCONFIG

cat > ios/Flutter/Release.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
XCCONFIG

cat > ios/Flutter/Profile.xcconfig <<'XCCONFIG'
#include "Generated.xcconfig"
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
XCCONFIG

echo "✅ Skrev Debug/Release/Profile.xcconfig"

echo
echo "==> Pod install"
cd ios
pod install
cd ..

echo
echo "==> Verifisering"
echo "--- ios/Flutter ---"
ls -la ios/Flutter
echo
echo "--- Generated.xcconfig head ---"
sed -n '1,80p' ios/Flutter/Generated.xcconfig || true
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
echo "4) Velg Runner target og bygg på nytt"
echo "5) Ikke åpne Runner.xcodeproj"
