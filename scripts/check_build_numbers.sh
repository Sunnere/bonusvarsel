#!/bin/bash
echo "=== pubspec.yaml ==="
grep "^version:" pubspec.yaml

echo ""
echo "=== Alle CURRENT_PROJECT_VERSION i pbxproj ==="
grep "CURRENT_PROJECT_VERSION" ios/Runner.xcodeproj/project.pbxproj

echo ""
echo "=== Info.plist bundle version ==="
grep -A1 "CFBundleVersion" ios/Runner/Info.plist
grep -A1 "CFBundleShortVersionString" ios/Runner/Info.plist
