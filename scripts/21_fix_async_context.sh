#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

# legg inn mounted-check før Navigator.of(context)
sed -i "s/await \(.*\);/await \1;\n    if (!mounted) return;/" "$FILE"

dart format "$FILE" || true
flutter analyze || true
