#!/usr/bin/env bash
set -e

FILE="pubspec.yaml"

cp "$FILE" "$FILE.bak_700"

if ! grep -q "in_app_purchase:" "$FILE"; then
  echo "➕ Legger til in_app_purchase"
  awk '
  /dependencies:/ {
    print;
    print "  in_app_purchase: ^3.1.11";
    next
  }
  { print }
  ' "$FILE" > tmp && mv tmp "$FILE"
fi

flutter pub get
echo "✅ IAP package installert"
