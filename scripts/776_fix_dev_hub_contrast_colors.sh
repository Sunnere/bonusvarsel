#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_776.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# 1) Gjør history-kortet mørkt og lesbart
text = text.replace(
"""      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black12),
      ),""",
"""      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF111827),
        border: Border.all(color: Colors.white24),
      ),""",
1
)

text = text.replace(
"""          const Text(
            'Alert simulation history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),""",
"""          const Text(
            'Alert simulation history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),""",
1
)

text = text.replace(
"""            const Text(
              'Ingen simuleringer ennå.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            )""",
"""            const Text(
              'Ingen simuleringer ennå.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFD1D5DB),
              ),
            )""",
1
)

text = text.replace(
"""                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black.withValues(alpha: 0.03),
                    border: Border.all(color: Colors.black12),
                  ),""",
"""                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF1F2937),
                    border: Border.all(color: Colors.white24),
                  ),""",
1
)

text = text.replace(
"""                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),""",
"""                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),""",
1
)

text = text.replace(
"""                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),""",
"""                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: Color(0xFFE5E7EB),
                        ),""",
1
)

text = text.replace(
"""                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),""",
"""                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w700,
                        ),""",
1
)

# 2) Gjør de midlertidige placeholder-kortene mørke og lesbare
text = text.replace(
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.black12),
            ),
            child: const Text('Diagnostics midlertidig skjult lokalt.'),
          ),""",
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF111827),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'Diagnostics midlertidig skjult lokalt.',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),""",
1
)

text = text.replace(
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.black12),
            ),
            child: const Text('System health midlertidig skjult lokalt.'),
          ),""",
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF111827),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'System health midlertidig skjult lokalt.',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),""",
1
)

text = text.replace(
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.black12),
            ),
            child: const Text('Stats midlertidig skjult lokalt.'),
          ),""",
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF111827),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'Stats midlertidig skjult lokalt.',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),""",
1
)

text = text.replace(
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.black12),
            ),
            child: const Text('Push test midlertidig skjult lokalt.'),
          ),""",
"""          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF111827),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'Push test midlertidig skjult lokalt.',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),""",
1
)

p.write_text(text)
print("✅ Fikset kontrastfarger i Dev Hub")
PY

flutter analyze
echo "✅ 776 ferdig"
