#!/usr/bin/env bash
set -euo pipefail

FILE="pubspec.yaml"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_707_add_in_app_purchase_dependency"
echo "✅ Backup laget: ${FILE}.bak_707_add_in_app_purchase_dependency"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("pubspec.yaml")
text = path.read_text()
original = text

if re.search(r"^\s*in_app_purchase:\s*", text, flags=re.MULTILINE):
    print("ℹ️ in_app_purchase finnes allerede i pubspec.yaml")
    sys.exit(0)

m = re.search(r"^dependencies:\s*$", text, flags=re.MULTILINE)
if not m:
    print("❌ Fant ikke dependencies: i pubspec.yaml")
    sys.exit(1)

insert_at = m.end()
text = text[:insert_at] + "\n  in_app_purchase: ^3.2.2" + text[insert_at:]

path.write_text(text)
print("✅ La til in_app_purchase i pubspec.yaml")
PY

flutter pub get
flutter analyze || true

echo
echo "Ferdig."
