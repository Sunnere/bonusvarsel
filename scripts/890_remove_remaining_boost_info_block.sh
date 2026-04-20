#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_890.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old = """          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boost',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lockedLine,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke boost-infoblokken")

text = text.replace(old, "", 1)

p.write_text(text)
print("✅ Fjernet gjenværende Boost-infoblokk")
PY

flutter analyze
echo "✅ 890 ferdig"
