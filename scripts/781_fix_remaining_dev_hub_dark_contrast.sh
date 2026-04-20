#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_781.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# 1) Seksjonstitler som mangler eksplisitt lys farge
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
          ),""",
)

text = text.replace(
"""          const Text(
            'Queue actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),""",
"""          const Text(
            'Queue actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),""",
)

text = text.replace(
"""          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),""",
"""          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),""",
)

# 2) Vanlige label-tekster i mørke kort
text = text.replace(
"""                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),""",
"""                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE5E7EB),
                      ),""",
)

text = text.replace(
"""              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),""",
"""              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFE5E7EB),
              ),""",
)

# 3) Score/Momentum labels
text = text.replace(
"""                  const Text('Score'),""",
"""                  const Text(
                    'Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),""",
)

text = text.replace(
"""                  const Text('Momentum'),""",
"""                  const Text(
                    'Momentum',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),""",
)

# 4) Reason/Simulated at-gråtoner til lysere kontrast
text = text.replace(
"""                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),""",
"""                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w700,
                ),""",
)

# 5) Mørke seksjonskort: hvit tekst i generelle header/subtitle blocks
text = re.sub(
    r"""TextStyle\(
(\s*)fontWeight:\s*FontWeight\.w900,
(\s*)\)""",
    r"""TextStyle(
\1fontWeight: FontWeight.w900,
\1color: Colors.white,
\2)""",
    text,
    count=6,
)

# 6) Sikre at mørke infobokser ikke har standard svart tekst
text = text.replace(
"""child: const Text(""",
"""child: const Text(
""",
)

p.write_text(text)
print("✅ Oppdatert gjenværende Dev Hub-kontrast")
PY

flutter analyze
echo "✅ 781 ferdig"
