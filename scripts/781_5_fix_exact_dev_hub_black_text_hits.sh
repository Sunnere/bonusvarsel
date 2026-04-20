#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_781_5.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

pairs = [
    (
"""          const Text(
            'Dev Hub build info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),""",
"""          const Text(
            'Dev Hub build info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
    (
"""          const Text(
            'Alert simulation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),""",
"""          const Text(
            'Alert simulation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),"""
    ),
    (
"""          const Text(
            'Queue actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),""",
"""          const Text(
            'Queue actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),"""
    ),
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
"""                        Text(
                          '${dispatch['body'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.90),
                            fontWeight: FontWeight.w700,
                          ),
                        ),""",
"""                        Text(
                          '${dispatch['body'] ?? '-'}',
                          style: const TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),"""
    ),
    (
"""                          Text(
                            'Reason: ${(evaluation['reason'] ?? '-').toString()}',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.90),
                              fontWeight: FontWeight.w700,
                            ),
                          ),""",
"""                          Text(
                            'Reason: ${(evaluation['reason'] ?? '-').toString()}',
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),"""
    ),
    (
"""                            Text(
                              'Cooldown remaining: ${evaluation['cooldownRemainingSec']} sec',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                              ),
                            ),""",
"""                            Text(
                              'Cooldown remaining: ${evaluation['cooldownRemainingSec']} sec',
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontWeight: FontWeight.w700,
                              ),
                            ),"""
    ),
]

changed = 0
for old, new in pairs:
    if old in text:
        text = text.replace(old, new, 1)
        changed += 1

if changed == 0:
    raise SystemExit("❌ Fant ingen eksakte svarte teksttreff å bytte")

p.write_text(text)
print(f"✅ Byttet {changed} eksakte svarte teksttreff")
PY

flutter analyze
echo "✅ 781.5 ferdig"
