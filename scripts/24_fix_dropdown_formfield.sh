#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

# Kun DropdownButtonFormField skal bruke initialValue
perl -0777 -pi -e "
s/DropdownButtonFormField<([^>]+)>\((.*?)value:/DropdownButtonFormField<\1>(\2initialValue:/gs
" "$FILE"

dart format "$FILE" || true
flutter analyze || true
