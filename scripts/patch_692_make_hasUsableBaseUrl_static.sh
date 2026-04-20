#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/api_service.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_692_make_hasUsableBaseUrl_static"
echo "✅ Backup laget: ${FILE}.bak_692_make_hasUsableBaseUrl_static"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/services/api_service.dart")
text = path.read_text()
original = text

changed = False

# Gjør helperen static, og gi den eksplisitt input så den kan brukes fra static context
pat = re.compile(
    r"""bool\s+_hasUsableBaseUrl\(\)\s*\{
\s*final\s+raw\s*=\s*baseUrl\.trim\(\);
\s*if\s*\(raw\.isEmpty\)\s*return\s*false;
\s*if\s*\(raw\.contains\("127\.0\.0\.1"\)\)\s*return\s*false;
\s*if\s*\(raw\.contains\("localhost"\)\)\s*return\s*false;
\s*return\s*true;
\s*\}""",
    re.VERBOSE,
)

repl = """static bool _hasUsableBaseUrl(String rawBaseUrl) {
    final raw = rawBaseUrl.trim();
    if (raw.isEmpty) return false;
    if (raw.contains("127.0.0.1")) return false;
    if (raw.contains("localhost")) return false;
    return true;
  }"""

new_text, count = pat.subn(repl, text, count=1)
if count:
    text = new_text
    changed = True

# Oppdater kallene
replacements = [
    ("_hasUsableBaseUrl()", "_hasUsableBaseUrl(baseUrl)"),
]

for old, new in replacements:
    if old in text:
        text = text.replace(old, new)
        changed = True

if not changed:
    print("⚠️ Fant ikke forventet _hasUsableBaseUrl-mønster. Ingen endring gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Gjorde _hasUsableBaseUrl static og oppdaterte kallene")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
