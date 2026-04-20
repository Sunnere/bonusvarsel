#!/bin/bash

echo "=== Sjekker GoogleService-Info.plist ==="
# Sjekk både Downloads og Documents
PLIST_PATH=""
if [ -f ~/Downloads/GoogleService-Info.plist ]; then
  PLIST_PATH=~/Downloads/GoogleService-Info.plist
elif [ -f ~/Documents/GoogleService-Info.plist ]; then
  PLIST_PATH=~/Documents/GoogleService-Info.plist
else
  echo "FEIL: Finner ikke GoogleService-Info.plist i Downloads eller Documents"
  exit 1
fi

echo "✅ Fant filen: $PLIST_PATH"

echo ""
echo "=== Kopierer til ios/Runner/ ==="
cp "$PLIST_PATH" ios/Runner/GoogleService-Info.plist
echo "✅ Kopiert til ios/Runner/GoogleService-Info.plist"

echo ""
echo "=== Sjekker bundle ID i filen ==="
grep "BUNDLE_ID" ios/Runner/GoogleService-Info.plist

echo ""
echo "=== Legger til Firebase-pakker i pubspec.yaml ==="
if grep -q "firebase_core" pubspec.yaml; then
  echo "Firebase allerede i pubspec.yaml"
else
  sed -i '' 's/  in_app_purchase: \^3.2.3/  in_app_purchase: ^3.2.3\n  firebase_core: ^3.6.0\n  firebase_auth: ^5.3.1\n  google_sign_in: ^6.2.1\n  sign_in_with_apple: ^6.1.1/' pubspec.yaml
  echo "✅ Firebase-pakker lagt til"
fi

echo ""
echo "=== Kjører flutter pub get ==="
flutter pub get

echo ""
echo "=== Ferdig ==="
