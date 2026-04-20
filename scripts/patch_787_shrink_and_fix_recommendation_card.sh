#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WIDGET="lib/widgets/best_recommendation_card.dart"

if [ ! -f "$WIDGET" ]; then
  echo "❌ Widget finnes ikke"
  exit 1
fi

cp "$WIDGET" "$WIDGET.bak_787_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/widgets/best_recommendation_card.dart")
text = path.read_text()

# --- 1. cap poeng + gjør mer realistisk ---
text = re.sub(
    r"final uplift = best\.upliftVsCurrent \?\? 0;",
    """final rawPoints = best.estimatedPoints;
            final safePoints = rawPoints > 5000 ? 5000 : rawPoints;
            final uplift = best.upliftVsCurrent ?? 0;""",
    text
)

# --- 2. mindre kort (padding + margin) ---
text = text.replace(
    "margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),",
    "margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),"
)

text = text.replace(
    "padding: const EdgeInsets.all(16),",
    "padding: const EdgeInsets.all(12),"
)

# --- 3. mindre tittel ---
text = text.replace(
    "fontSize: 19,",
    "fontSize: 16,"
)

# --- 4. mindre subtitle ---
text = text.replace(
    "fontSize: 14,",
    "fontSize: 13,"
)

# --- 5. endre poeng visning ---
text = re.sub(
    r"text: '\$\{best\.estimatedPoints\} poeng'",
    "text: '+${safePoints} poeng'",
    text
)

# --- 6. kortere summary ---
text = re.sub(
    r"BonusRecommendationEngine\.recommendationSummary\([^\)]*\)",
    "best.subtitle",
    text
)

# --- 7. CTA mindre ---
text = text.replace(
    "padding: const EdgeInsets.symmetric(vertical: 14),",
    "padding: const EdgeInsets.symmetric(vertical: 10),"
)

# --- 8. fjern litt spacing ---
text = text.replace("const SizedBox(height: 14),", "const SizedBox(height: 8),")
text = text.replace("const SizedBox(height: 12),", "const SizedBox(height: 6),")

path.write_text(text)
print("✅ Shrink + realistiske tall ferdig")
PY

echo
echo "✅ Ferdig"
echo "Kjør:"
echo "flutter run"
