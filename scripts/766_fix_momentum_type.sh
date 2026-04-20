#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# fix casting to num
text = re.sub(
    r"evaluation\['momentum'\]\s+as\s+num\?",
    "evaluation['momentum']?.toString()",
    text
)

# fix direct numeric assignment
text = re.sub(
    r"final\s+(\w+)\s*=\s*evaluation\['momentum'\];",
    r"final \1 = evaluation['momentum']?.toString();",
    text
)

p.write_text(text)
print("✅ momentum type fix applied")
PY

flutter analyze
echo "✅ 766 ferdig"
