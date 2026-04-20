#!/usr/bin/env bash
set -euo pipefail

IOS_DIR="ios"
FLUTTER_DIR="$IOS_DIR/Flutter"

DEBUG_XC="$FLUTTER_DIR/Debug.xcconfig"
RELEASE_XC="$FLUTTER_DIR/Release.xcconfig"
PROFILE_XC="$FLUTTER_DIR/Profile.xcconfig"

for f in "$DEBUG_XC" "$RELEASE_XC" "$PROFILE_XC"; do
  [[ -f "$f" ]] || { echo "❌ Fant ikke $f"; exit 1; }
  cp "$f" "$f.bak_893.$(date +%s)"
done

python3 <<'PY'
from pathlib import Path

files = {
    Path("ios/Flutter/Debug.xcconfig"): '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
    Path("ios/Flutter/Release.xcconfig"): '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
    Path("ios/Flutter/Profile.xcconfig"): '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"',
}

for path, include_line in files.items():
    text = path.read_text()
    if include_line in text:
        print(f"✅ Finnes allerede i {path}")
        continue

    lines = text.splitlines()
    # legg include øverst for å sikre at Pods kobles inn
    new_text = include_line + "\n" + text
    path.write_text(new_text)
    print(f"✅ La til include i {path}")
PY

echo
echo "== Kjør pod install på nytt =="
cd ios
pod install
cd ..

echo
flutter analyze
echo "✅ 893 ferdig"
