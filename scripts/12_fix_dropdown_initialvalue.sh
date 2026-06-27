#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || exit 0

# Bytt value: til initialValue: kun for DropdownButtonFormField
sed -i 's/DropdownButtonFormField<String>(\([^)]*\)value:/DropdownButtonFormField<String>(\1initialValue:/g' "$FILE"

dart format "$FILE"
flutter analyze
