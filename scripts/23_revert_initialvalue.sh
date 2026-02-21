#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

sed -i "s/initialValue:/value:/g" "$FILE"

dart format "$FILE" || true
flutter analyze || true
