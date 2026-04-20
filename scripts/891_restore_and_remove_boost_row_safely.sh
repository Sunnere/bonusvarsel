#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
BAK="$(ls -1t lib/pages/eb_shopping_page.dart.bak_890.* 2>/dev/null | head -n 1 || true)"

[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }
[[ -n "$BAK" ]] || { echo "❌ Fant ikke backup fra 890"; exit 1; }

cp "$FILE" "$FILE.bak_891_before_restore.$(date +%s)"
cp "$BAK" "$FILE"
echo "✅ Gjenopprettet fra: $BAK"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old = """        Expanded(
          child: Column(
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
    raise SystemExit("❌ Fant ikke eksakt boost-rad for trygg fjerning")

text = text.replace(old, "", 1)

p.write_text(text)
print("✅ Fjernet hele boost-raden trygt")
PY

flutter analyze
echo "✅ 891 ferdig"
