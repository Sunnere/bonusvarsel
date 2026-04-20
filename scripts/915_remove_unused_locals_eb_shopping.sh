#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak_915.$(date +%s)"

python3 <<'PY'
from pathlib import Path
p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()

for line in [
    "  final cs = Theme.of(context).colorScheme;\n",
    "  final String lockedLine =\n",
    "  final String ctaLabel =\n",
]:
    if line in text:
        text = text.replace(line, "")

# rydder også eventuelle fortsettelseslinjer for lockedLine/ctaLabel enkelt
text = text.replace(
"""      ? (scope == null
          ? 'Du går glipp av ekstra poeng i $hiddenCount butikker'
          : 'Du går glipp av ekstra poeng i $hiddenCount $scope-butikker')
      : (scope == null
          ? 'Du går glipp av ekstra poeng'
          : 'Du går glipp av ekstra poeng hos $scope');
""",
""
)

text = text.replace(
"""      (scope == null) ? '🔓 Få alle poengene' : '🔓 Lås opp $scope-poeng';
""",
""
)

p.write_text(text)
print("✅ Fjernet ubrukte lokale variabler")
PY

flutter analyze
