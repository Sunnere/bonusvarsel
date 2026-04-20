#!/usr/bin/env bash
set -euo pipefail

WIDGET="lib/widgets/best_recommendation_card.dart"

if [ ! -f "$WIDGET" ]; then
  echo "❌ Widget mangler"
  exit 1
fi

cp "$WIDGET" "$WIDGET.bak_788_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/widgets/best_recommendation_card.dart")
text = path.read_text()

# --- fjern gammel uplift ---
text = re.sub(
    r"final uplift = best\.upliftVsCurrent \?\? 0;",
    """final rawPoints = best.estimatedPoints;
final safePoints = rawPoints > 5000 ? 5000 : rawPoints;

// realistisk uplift (maks 2000)
final rawUplift = best.upliftVsCurrent ?? 0;
final uplift = rawUplift > 2000 ? 2000 : rawUplift;
""",
    text
)

# --- fjern +100000 visning ---
text = re.sub(
    r"_chip\(\s*text:\s*'\+\$\{uplift\} vs vanlig'.*?\),",
    """_chip(
  text: uplift > 0 ? '+${uplift} ekstra' : 'Standard',
  fg: const Color(0xFFFFC44D),
  bg: const Color(0xFF3A2B10),
  border: const Color(0xFF7A5A1E),
),""",
    text,
    flags=re.DOTALL
)

path.write_text(text)
print("✅ Fake uplift fjernet og erstattet med realistisk verdi")
PY

echo
echo "✅ Ferdig"
echo "Kjør:"
echo "flutter run"
