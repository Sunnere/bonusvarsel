#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

# kommenter ut linjen som definerer _favKey
sed -i "s/static const String _favKey.*/\/\/ removed unused _favKey/" "$FILE"

dart format "$FILE" || true
flutter analyze || true
