#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_660_remove_bottom_upgrade_section"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# Finn blokk som inneholder "klar" eller "Oppgrader"
pattern = re.compile(
    r"""
\s*Container\(
.*?
(Text\(
.*?(klar|Oppgrader|Premium)
.*?\)
.*?
)
.*?\),
""",
    re.DOTALL | re.VERBOSE | re.IGNORECASE
)

matches = list(pattern.finditer(text))

if not matches:
    print("⚠️ Fant ikke tydelig bottom CTA-blokk automatisk.")
    sys.exit(2)

# Fjern siste match (typisk nederst på siden)
last = matches[-1]
start, end = last.span()

text = text[:start] + text[end:]

path.write_text(text)
print("✅ Fjernet nederste upgrade/CTA-seksjon")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
