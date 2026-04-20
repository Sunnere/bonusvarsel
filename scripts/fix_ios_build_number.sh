#!/bin/bash
PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"

echo "=== Backup ==="
cp $PBXPROJ ${PBXPROJ}.bak
echo "Backup lagret"

echo ""
echo "=== Fikser CURRENT_PROJECT_VERSION til å bruke Flutter build number ==="
sed -i '' 's/CURRENT_PROJECT_VERSION = 1;/CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";/g' $PBXPROJ

echo ""
echo "=== Resultat ==="
grep "CURRENT_PROJECT_VERSION" $PBXPROJ

echo ""
echo "=== Bygger ny IPA ==="
flutter clean && flutter pub get && flutter build ipa --release

echo ""
echo "=== Ferdig ==="
grep "^version:" pubspec.yaml
