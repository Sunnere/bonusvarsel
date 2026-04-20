#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"

echo "==> patch_739_repair_xcode_pbxproj_xcconfig_refs"

if [ ! -f "$PBXPROJ" ]; then
  echo "❌ Fant ikke $PBXPROJ"
  exit 1
fi

cp "$PBXPROJ" "$PBXPROJ.bak_739_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

pbxproj = Path("ios/Runner.xcodeproj/project.pbxproj")
text = pbxproj.read_text()

# Sikrer at Flutter xcconfig file references finnes med riktige paths.
replacements = {
    r'path = Flutter/Debug\.xcconfig;': 'path = Flutter/Debug.xcconfig;',
    r'path = Flutter/Release\.xcconfig;': 'path = Flutter/Release.xcconfig;',
    r'path = Flutter/Profile\.xcconfig;': 'path = Flutter/Profile.xcconfig;',
}

for pattern, repl in replacements.items():
    text = re.sub(pattern, repl, text)

pbxproj.write_text(text)
print("✅ Normaliserte Flutter xcconfig path entries")
PY

echo "==> Viser Flutter refs i project.pbxproj"
grep -n "Flutter/Debug.xcconfig\|Flutter/Release.xcconfig\|Flutter/Profile.xcconfig" "$PBXPROJ" || true

echo
echo "==> Rydder Xcode workspace/cache"
rm -rf ios/Runner.xcworkspace/xcuserdata || true
rm -rf ios/Runner.xcodeproj/xcuserdata || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

echo
echo "==> Pod install"
cd ios
pod install
cd ..

echo
echo "✅ Ferdig"
echo "Gjør nå nøyaktig dette:"
echo "1) lukk Xcode helt"
echo "2) åpne workspace: open ios/Runner.xcworkspace"
echo "3) Product > Clean Build Folder"
echo "4) bygg igjen"
echo
echo "Hvis feilen fortsatt står:"
echo "Kjør disse kommandoene og lim inn output:"
echo "grep -n \"baseConfigurationReference\" ios/Runner.xcodeproj/project.pbxproj | head -80"
echo "grep -n \"Debug.xcconfig\\|Release.xcconfig\\|Profile.xcconfig\" ios/Runner.xcodeproj/project.pbxproj | head -120"
