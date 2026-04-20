#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_778_1.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

old = """          if (_loadingHealth)
            const Text(
              'Laster system health...',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
"""

new = """          if (_loadingHealth) ...[
            const Text(
              'Laster system health...',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            Wrap(
"""

if old not in text:
    raise SystemExit("❌ Fant ikke forventet _loadingHealth-blokk")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Fikset collection-if i system health")
PY

flutter analyze
echo "✅ 778.1 ferdig"
