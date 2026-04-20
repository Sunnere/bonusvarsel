#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

cp "$FILE" "${FILE}.bak_695_connect_checkout"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/premium_page.dart")
text = path.read_text()

# legg til import
if "checkout_page.dart" not in text:
    text = text.replace(
        "import '../services/checkout_service.dart';",
        "import '../services/checkout_service.dart';\nimport 'checkout_page.dart';"
    )

# erstatt snackbar med navigation
pattern = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(.*?\);"

replacement = """
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const CheckoutPage()),
);
"""

text = re.sub(pattern, replacement, text, flags=re.DOTALL)

path.write_text(text)
print("✅ Navigasjon lagt inn")
PY

echo
flutter analyze || true

echo
echo "Kjør:"
echo "flutter run -d 00008110-001138643E60401E"
