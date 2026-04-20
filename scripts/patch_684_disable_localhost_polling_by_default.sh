#!/usr/bin/env bash
set -euo pipefail

FILE1="lib/config/api_config.dart"
FILE2="lib/services/api_service.dart"

if [ ! -f "$FILE1" ]; then
  echo "❌ Fant ikke $FILE1"
  exit 1
fi

if [ ! -f "$FILE2" ]; then
  echo "❌ Fant ikke $FILE2"
  exit 1
fi

cp "$FILE1" "${FILE1}.bak_684_disable_localhost_polling_by_default"
cp "$FILE2" "${FILE2}.bak_684_disable_localhost_polling_by_default"
echo "✅ Backup laget:"
echo "  ${FILE1}.bak_684_disable_localhost_polling_by_default"
echo "  ${FILE2}.bak_684_disable_localhost_polling_by_default"

python3 - <<'PY'
from pathlib import Path
import re
import sys

file1 = Path("lib/config/api_config.dart")
file2 = Path("lib/services/api_service.dart")

text1 = file1.read_text()
text2 = file2.read_text()

orig1 = text1
orig2 = text2

changed = False

# 1) api_config.dart: fjern localhost som default
text1_new = text1.replace(
    "defaultValue: 'http://127.0.0.1:8080'",
    "defaultValue: ''"
)
if text1_new != text1:
    text1 = text1_new
    changed = True

# 2) api_service.dart: fjern localhost som native default
text2_new = text2.replace(
    "static const String _nativeDefaultBaseUrl = 'http://127.0.0.1:8080';",
    "static const String _nativeDefaultBaseUrl = '';"
)
if text2_new != text2:
    text2 = text2_new
    changed = True

# 3) Legg inn helper for å vite om base URL er brukbar
if "_hasUsableBaseUrl()" not in text2:
    marker = "  String get baseUrl"
    idx = text2.find(marker)
    if idx != -1:
        helper = """
  bool _hasUsableBaseUrl() {
    final raw = baseUrl.trim();
    if (raw.isEmpty) return false;
    if (raw.contains('127.0.0.1:8080')) return false;
    if (raw.contains('localhost:8080')) return false;
    return true;
  }

"""
        text2 = text2[:idx] + helper + text2[idx:]
        changed = True

# 4) Guard rundt polling error loop / notifications polling
# Vi prøver å finne polling-metoden og legge inn early return før request
patterns = [
    (
        r"(final decoded = await _getMap\('/v1/notifications/activated\$suffix'\);)",
        "if (!_hasUsableBaseUrl()) {\n      return <String, dynamic>{};\n    }\n    \\1"
    ),
]

for pat, repl in patterns:
    new_text, count = re.subn(pat, repl, text2, count=1)
    if count:
        text2 = new_text
        changed = True

# 5) Guard i poll-løkken hvis den finnes
if "Polling skipped: no usable baseUrl configured." not in text2:
    poll_patterns = [
        (
            r"(while\s*\([^\)]*\)\s*\{\n)",
            "\\1      if (!_hasUsableBaseUrl()) {\n        print('Polling skipped: no usable baseUrl configured.');\n        return;\n      }\n"
        ),
        (
            r"(\s*try\s*\{\n\s*final decoded = await _getMap\('/v1/notifications/activated\$suffix'\);)",
            "      if (!_hasUsableBaseUrl()) {\n        print('Polling skipped: no usable baseUrl configured.');\n        return;\n      }\n\\1"
        ),
    ]
    for pat, repl in poll_patterns:
        new_text, count = re.subn(pat, repl, text2, count=1)
        if count:
            text2 = new_text
            changed = True
            break

if not changed:
    print("⚠️ Fant ingen kjente mønstre å endre.")
    sys.exit(2)

file1.write_text(text1)
file2.write_text(text2)
print("✅ Deaktiverte localhost polling som default")
PY

echo
echo "==> Verifiser endringer"
grep -n "defaultValue:\|_nativeDefaultBaseUrl\|_hasUsableBaseUrl\|Polling skipped" "$FILE1" "$FILE2" || true

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
