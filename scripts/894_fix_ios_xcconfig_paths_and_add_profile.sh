#!/usr/bin/env bash
set -euo pipefail

mkdir -p ios/Flutter

for f in ios/Flutter/Debug.xcconfig ios/Flutter/Release.xcconfig; do
  [[ -f "$f" ]] || { echo "❌ Fant ikke $f"; exit 1; }
  cp "$f" "$f.bak_894.$(date +%s)"
done

if [[ -f ios/Flutter/Profile.xcconfig ]]; then
  cp ios/Flutter/Profile.xcconfig ios/Flutter/Profile.xcconfig.bak_894.$(date +%s)
fi

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

echo "✅ Skrev nye xcconfig-filer"

cd ios
pod install
cd ..

flutter analyze
echo "✅ 894 ferdig"
