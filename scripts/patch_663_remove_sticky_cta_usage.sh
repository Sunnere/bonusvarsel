#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_663_remove_sticky_cta_usage"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

patterns = [
    r"""
[ \t]*Positioned\(
.*?
_StickyCta\(
.*?
\),
[ \t]*\),
""",
    r"""
[ \t]*Align\(
.*?
_StickyCta\(
.*?
\),
[ \t]*\),
""",
    r"""
[ \t]*_StickyCta\(
.*?
\),
""",
]

changed = False
for pat in patterns:
    new_text, count = re.subn(pat, "", text, flags=re.DOTALL | re.VERBOSE)
    if count > 0:
        text = new_text
        changed = True

text = re.sub(r"\n{3,}", "\n\n", text)

if not changed:
    print("❌ Fant ikke bruk av _StickyCta. Ingen endring gjort.")
    sys.exit(1)

path.write_text(text)
print("✅ Fjernet bruk av _StickyCta nederst på siden")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true
