#!/usr/bin/env bash
set -euo pipefail

echo "== A1: Flutter / Dart info =="
flutter --version
dart --version

echo
echo "== A2: Clean + get =="
flutter clean
flutter pub get

echo
echo "== A3: Analyze (må være 0 errors) =="
flutter analyze

echo
echo "== A4: Format (skal ikke feile) =="
dart format .

echo
echo "✅ A ferdig"
