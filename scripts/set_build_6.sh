#!/bin/bash
# Sett build number til 6
sed -i '' 's/^version: .*/version: 1.0.0+6/' pubspec.yaml
echo "=== Versjon satt ==="
grep "^version:" pubspec.yaml

echo ""
echo "=== Bygger IPA ==="
flutter clean && flutter pub get && flutter build ipa --release

echo ""
echo "=== Ferdig ==="
grep "^version:" pubspec.yaml
