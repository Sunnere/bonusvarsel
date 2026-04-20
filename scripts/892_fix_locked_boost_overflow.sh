#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_892.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old = """    if (isLocked) {
      return Row(
        children: [
          const Icon(Icons.lock, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            "Boost – oppgrader",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
"""

new = """    if (isLocked) {
      return const Text(
        '🔒 Boost i Premium',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    }
"""

if old not in text:
    raise SystemExit("❌ Fant ikke eksakt isLocked-blokk")

text = text.replace(old, new, 1)

p.write_text(text)
print("✅ Erstattet overflow-raden med kompakt locked-tekst")
PY

flutter analyze
echo "✅ 892 ferdig"
