#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_665_fix_premium_page_dangling_comma"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

echo
echo "==> Utdrag før fix (linje 520-532)"
sed -n '520,532p' "$FILE" || true

python3 - <<'PY'
from pathlib import Path

path = Path("lib/pages/premium_page.dart")
lines = path.read_text().splitlines()

new_lines = []
removed = 0

for line in lines:
    if line.strip() == ",":
        removed += 1
        continue
    new_lines.append(line)

path.write_text("\n".join(new_lines) + "\n")
print(f"✅ Fjernet {removed} løs(e) komma-linje(r)")
PY

echo
echo "==> Utdrag etter fix (linje 520-532)"
sed -n '520,532p' "$FILE" || true

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
