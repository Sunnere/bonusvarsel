#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

sed -i "s/value:/initialValue:/g" "$FILE"

dart format "$FILE" || true
flutter analyze || true
