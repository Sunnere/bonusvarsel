#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_819.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()
original = text

# 1. Gjør _pushTestExpanded final
text = re.sub(
    r"bool _pushTestExpanded =",
    "final bool _pushTestExpanded =",
    text
)

# 2. Fjern ubrukte fields
unused_fields = [
    r"\n\s*List<.*?> _expandedHistoryRows = .*?;",
    r"\n\s*var _pushTestKey = .*?;",
]

for pattern in unused_fields:
    text = re.sub(pattern, "", text)

# 3. Fjern ubrukte metoder
unused_methods = [
    r"\n\s*String _simulationSummaryText\([\s\S]*?\n\s*\}",
    r"\n\s*Color _diagnosticColor\([\s\S]*?\n\s*\}",
]

for pattern in unused_methods:
    text = re.sub(pattern, "", text)

if text == original:
    raise SystemExit("❌ Ingen endringer gjort (pattern traff ikke)")

p.write_text(text)
print("✅ Fjernet warnings i Dev Hub")
PY

echo
flutter analyze
echo "✅ 819 ferdig"
