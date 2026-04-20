#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/widgets/best_recommendation_card.dart"

echo "==> patch_794_fix_recommendation_cta_expression"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak_794_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/widgets/best_recommendation_card.dart")
t = p.read_text()

# Fiks header-tekst trygt
t = re.sub(
    r"child:\s*Text\(\s*locked.*?fontWeight:\s*FontWeight\.w900,\s*\),",
    """child: Text(
                          locked
                              ? '🔒 Du går glipp av dette'
                              : state.tier == 'elite'
                                  ? '🚀 Optimal strategi (maks verdi)'
                                  : '⭐ Beste valg for deg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),""",
    t,
    count=1,
    flags=re.DOTALL,
)

# Fiks ctaLabel trygt
t = re.sub(
    r"final ctaLabel = .*?;\n",
    """final ctaLabel = locked
                ? 'Lås opp og få bedre valg'
                : state.tier == 'elite'
                    ? 'Se full strategi'
                    : 'Se hvorfor dette er best';
""",
    t,
    count=1,
    flags=re.DOTALL,
)

p.write_text(t)
print("✅ Fikset header + ctaLabel i best_recommendation_card.dart")
PY

echo
echo "==> Verifisering"
grep -n "ctaLabel\\|Du går glipp av dette\\|Optimal strategi\\|Se full strategi" "$FILE" || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) flutter run -d macos"
