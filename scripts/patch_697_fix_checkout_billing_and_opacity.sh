#!/usr/bin/env bash
set -euo pipefail

SERVICE="lib/services/checkout_service.dart"
CHECKOUT="lib/pages/checkout_page.dart"

# --- backup ---
cp "$SERVICE" "${SERVICE}.bak_697" || true
cp "$CHECKOUT" "${CHECKOUT}.bak_697" || true
echo "✅ Backup laget"

# --- fix checkout_service ---
python3 - <<'PY'
from pathlib import Path

path = Path("lib/services/checkout_service.dart")
text = path.read_text()

changed = False

if "setBilling" not in text:
    insert = """

  Future<void> setBilling(String value) async {
    _billing = value;
  }

"""
    text = text.replace(
        "String _billing = 'monthly';",
        "String _billing = 'monthly';" + insert
    )
    changed = True

if changed:
    path.write_text(text)
    print("✅ setBilling lagt til")
else:
    print("ℹ️ setBilling finnes allerede")
PY

# --- fix withOpacity ---
python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/checkout_page.dart")
text = path.read_text()

# bytt withOpacity → withValues
text = re.sub(r"\.withOpacity\((.*?)\)", r".withValues(alpha: \1)", text)

path.write_text(text)
print("✅ withOpacity fikset")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig. Kjør:"
echo "flutter run -d 00008110-001138643E60401E"
