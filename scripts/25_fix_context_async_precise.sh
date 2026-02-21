#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

# legg inn mounted check før Navigator.of(context)
perl -0777 -pi -e "
s/await (.*?);\n(\s*)Navigator\.of\(context\)/await \1;\n\2if (!mounted) return;\n\2Navigator.of(context)/gs
" "$FILE"

dart format "$FILE" || true
flutter analyze || true
