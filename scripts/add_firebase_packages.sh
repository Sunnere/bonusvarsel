#!/bin/bash

echo "=== Legger til Firebase-pakker ==="
if grep -q "firebase_core" pubspec.yaml; then
  echo "Firebase allerede i pubspec.yaml"
else
  sed -i '' 's/  in_app_purchase: \^3.2.3/  in_app_purchase: ^3.2.3\n  firebase_core: ^3.6.0\n  firebase_auth: ^5.3.1\n  google_sign_in: ^6.2.1\n  sign_in_with_apple: ^6.1.1/' pubspec.yaml
  echo "✅ Pakker lagt til"
fi

echo ""
echo "=== Kjører flutter pub get ==="
flutter pub get

echo ""
echo "=== Sjekker at pakkene kom inn ==="
grep -E "firebase|google_sign|sign_in_with_apple" pubspec.yaml

echo ""
echo "=== Ferdig ==="
