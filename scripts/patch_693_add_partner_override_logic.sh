#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_693_partner_override"
echo "✅ Backup laget: ${FILE}.bak_693_partner_override"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/services/checkout_service.dart")
text = path.read_text()
changed = False

# 1. legg til partner flag hvis ikke finnes
if "_isPartner" not in text:
    insert = """

  bool _isPartner = false;

  bool get isPartner => _isPartner;

  Future<void> setPartner(bool value) async {
    _isPartner = value;
  }

"""
    text = text.replace(
        "String _billing = 'monthly';",
        "String _billing = 'monthly';" + insert
    )
    changed = True

# 2. legg til effectivePlan getter
if "effectivePlan" not in text:
    insert = """

  String get effectivePlan {
    if (_isPartner && _plan.toLowerCase() == 'premium') {
      return 'elite';
    }
    return _plan.toLowerCase();
  }

"""
    text = text.replace(
        "Map<String, dynamic> toPayload() {",
        insert + "\n  Map<String, dynamic> toPayload() {"
    )
    changed = True

# 3. utvid payload
if "'effectivePlan'" not in text:
    text = text.replace(
        "'billing': _billing,",
        "'billing': _billing,\n      'effectivePlan': effectivePlan,"
    )
    changed = True

if not changed:
    print("⚠️ Ingen endringer gjort")
    exit(2)

path.write_text(text)
print("✅ Partner override lagt inn")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Test:"
echo "  flutter run -d 00008110-001138643E60401E"
