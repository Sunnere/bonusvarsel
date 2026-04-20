#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_781_3.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

replacements = [
    (
"""          const Text(
            'Queue items',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),""",
"""          const Text(
            'Queue items',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),"""
    ),
    (
"""            const Text(
              'Ingen queue-items ennå.',
              style: TextStyle(fontWeight: FontWeight.w700),
            )""",
"""            const Text(
              'Ingen queue-items ennå.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFD1D5DB),
              ),
            )"""
    ),
    (
"""                      Text(
                        '${dispatch['body'] ?? '-'}',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w700,
                        ),
                      ),""",
"""                      Text(
                        '${dispatch['body'] ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),"""
    ),
    (
"""          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),""",
"""          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),"""
    ),
]

changed = 0
for old, new in replacements:
    if old in text:
        text = text.replace(old, new, 1)
        changed += 1

if changed == 0:
    raise SystemExit("❌ Fant ingen av de forventede mørke tekstblokkene")

p.write_text(text)
print(f"✅ Oppdaterte {changed} mørke tekstblokker i Dev Hub")
PY

flutter analyze
echo "✅ 781.3 ferdig"
