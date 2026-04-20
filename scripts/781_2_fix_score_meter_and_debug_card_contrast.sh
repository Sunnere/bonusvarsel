#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_781_2.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# 1) Alert simulation title
text = text.replace(
"""          const Text(
            'Alert simulation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
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
)

# 2) "Ingen simulering..." fallback
text = text.replace(
"""            const Text(
              'Ingen simulering kjørt ennå.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFD1D5DB),
              ),
            )""",
"""            const Text(
              'Ingen simulering kjørt ennå.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFD1D5DB),
              ),
            )"""
)

# 3) _scoreMeter label text
text = re.sub(
    r"""const Text\(
\s*'Score',
\s*style:\s*TextStyle\(
\s*color:\s*Colors\.white,
\s*fontWeight:\s*FontWeight\.w800,
\s*\),
\s*\),""",
    """const Text(
                    'Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),""",
    text,
)

# If _scoreMeter has generic label text with missing color, add it
text = text.replace(
"""          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),""",
"""          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),"""
)

text = text.replace(
"""          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),""",
"""          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),"""
)

# 4) score meter helper text/value colors
text = text.replace(
"""              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),""",
"""              style: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),"""
)

text = text.replace(
"""              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.90),
                fontWeight: FontWeight.w900,
              ),""",
"""              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),"""
)

# 5) debug card generic text on dark background
text = text.replace(
"""            child: Text(
              line,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),""",
"""            child: Text(
              line,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFE5E7EB),
              ),
            ),"""
)

# 6) any debug section title
text = text.replace(
"""          const Text(
            'Rule debug',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),""",
"""          const Text(
            'Rule debug',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),"""
)

p.write_text(text)
print("✅ Fikset score meter/debug card-kontrast")
PY

flutter analyze
echo "✅ 781.2 ferdig"
