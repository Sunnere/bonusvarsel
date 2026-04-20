#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_910.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

blocks = [
"""                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _showFreeVsPremium(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.white.withValues(alpha: 0.88)),
                          const SizedBox(width: 8),
                          Text(
                            'Sammenlign nivåer',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
""",
"""                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _showFreeVsPremium(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.white.withValues(alpha: 0.88)),
                          const SizedBox(width: 8),
                          Text(
                            'Sammenlign nivåer',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
""",
]

changed = False
for old in blocks:
    if old in text:
        text = text.replace(old, "", 1)
        changed = True
        break

if not changed:
    raise SystemExit("❌ Fant ikke eksakt 'Sammenlign nivåer'-blokk")

p.write_text(text)
print("✅ Fjernet 'Sammenlign nivåer' presist")
PY

flutter analyze
echo "✅ 910 ferdig"
