#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_alerts_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_863.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_alerts_page.dart")
text = p.read_text()
original = text

repls = [
(
"""                color: const Color(0xFF111827),""",
"""                color: const Color(0xFF065F46),"""
),
(
"""                      color: Colors.white,""",
"""                      color: const Color(0xFFECFDF5),"""
),
(
"""                      color: Color(0xFFD1D5DB),""",
"""                      color: Color(0xFFD1FAE5),"""
),
(
"""        color: isTop ? const Color(0xFFFFFBEB) : Colors.white,""",
"""        color: isTop ? const Color(0xFFECFDF5) : Colors.white,"""
),
(
"""          color: isTop ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),""",
"""          color: isTop ? const Color(0xFF34D399) : const Color(0xFFE5E7EB),"""
),
(
"""                    color: const Color(0xFFFEF3C7),""",
"""                    color: const Color(0xFFD1FAE5),"""
),
(
"""                    border: Border.all(color: const Color(0xFFF59E0B)),""",
"""                    border: Border.all(color: const Color(0xFF34D399)),"""
),
(
"""                      color: Color(0xFFB45309),""",
"""                      color: Color(0xFF047857),"""
),
(
"""                    '🏆 TOPPVARSEL',""",
"""                    '🏆 BESTE VARSEL',"""
),
(
"""                  color: const Color(0xFFDCFCE7),""",
"""                  color: const Color(0xFFBBF7D0),"""
),
(
"""                  border: Border.all(color: const Color(0xFF86EFAC)),""",
"""                  border: Border.all(color: const Color(0xFF22C55E)),"""
),
(
"""                    color: Color(0xFF166534),""",
"""                    color: Color(0xFF14532D),"""
),
(
"""                  color: Colors.white,""",
"""                  color: const Color(0xFFF0FDF4),"""
),
]

changed = 0
for old, new in repls:
    if old in text:
        text = text.replace(old, new, 1)
        changed += 1

old_empty = """              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Ingen aktive varsler akkurat nå.',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )"""

new_empty = """              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Text(
                  'Ingen aktive varsler akkurat nå.',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )"""

if old_empty in text:
    text = text.replace(old_empty, new_empty, 1)
    changed += 1

if changed == 0 or text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print(f"✅ Gjorde {changed} grønnere UI-endringer i alerts-siden")
PY

flutter analyze
echo "✅ 863 ferdig"
