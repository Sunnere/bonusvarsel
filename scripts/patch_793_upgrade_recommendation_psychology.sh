#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/best_recommendation_card.dart"

cp "$FILE" "$FILE.bak_793_$(date +%Y%m%d_%H%M%S)"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/best_recommendation_card.dart")
t = p.read_text()

# smarter header basert på tier
t = t.replace(
"locked ? '🔒 Beste valg du kan låse opp' : '⭐ Beste valg akkurat nå'",
"""locked
    ? '🔒 Du går glipp av dette'
    : state.tier == 'elite'
        ? '🚀 Optimal strategi (maks verdi)'
        : '⭐ Beste valg for deg'"""
)

# sterkere CTA
t = t.replace(
"final ctaLabel = locked",
"""final ctaLabel = locked
    ? 'Lås opp og få bedre valg'
    : state.tier == 'elite'
        ? 'Se full strategi'
        : 'Se hvorfor dette er best'"""
)

p.write_text(t)
print("✅ Psychology upgrade applied")
PY

echo "✅ Ferdig"
echo "Kjør:"
echo "flutter run"
