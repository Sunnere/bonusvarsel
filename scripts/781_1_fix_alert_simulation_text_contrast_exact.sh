#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_781_1.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

replacements = [
    (
"""          if (result == null)
            const Text(
              'Ingen simulering kjørt ennå.',
              style: TextStyle(fontWeight: FontWeight.w700),
            )""",
"""          if (result == null)
            const Text(
              'Ingen simulering kjørt ennå.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFD1D5DB),
              ),
            )"""
    ),
    (
"""              Text(
                'Reason: ${(evaluation['reason'] ?? '-').toString()}',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w700,
                ),
              ),""",
"""              Text(
                'Reason: ${(evaluation['reason'] ?? '-').toString()}',
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontWeight: FontWeight.w700,
                ),
              ),"""
    ),
    (
"""                Text(
                  'Cooldown remaining: ${evaluation['cooldownRemainingSec']} sec',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),""",
"""                Text(
                  'Cooldown remaining: ${evaluation['cooldownRemainingSec']} sec',
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontWeight: FontWeight.w700,
                  ),
                ),"""
    ),
    (
"""            Text(
              'Simulated at: ${result['simulatedAt'] ?? '-'}',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),""",
"""            Text(
              'Simulated at: ${result['simulatedAt'] ?? '-'}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w700,
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
    raise SystemExit("❌ Fant ingen av de forventede kontrast-blokkene")

p.write_text(text)
print(f"✅ Oppdaterte {changed} kontrast-blokker i alert simulation")
PY

flutter analyze
echo "✅ 781.1 ferdig"
