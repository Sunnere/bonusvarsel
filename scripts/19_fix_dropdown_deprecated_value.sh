#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# Bytt kun i DropdownButtonFormField<String>
s = re.sub(
    r"DropdownButtonFormField<String>\(\s*value:",
    "DropdownButtonFormField<String>(\n                        initialValue:",
    s,
)

p.write_text(s, encoding="utf-8")
print("✅ Byttet 'value:' til 'initialValue:' i DropdownButtonFormField")
PY

dart format "$FILE"
flutter analyze
