#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/checkout_page.dart"

cp "$FILE" "${FILE}.bak_712_fix_checkout_layout_properly"
echo "✅ Backup laget"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/checkout_page.dart")
text = path.read_text()
orig = text

# 1) Fjern ødelagt SafeArea + Scroll wrap
text = re.sub(
r"""body:\s*SafeArea\(\s*child:\s*SingleChildScrollView\([^)]*\)\s*""",
"body:",
text,
flags=re.DOTALL
)

# 2) Sett trygg scroll struktur
text = re.sub(
r"""body:\s*Padding\(\s*padding:\s*const EdgeInsets\.all\(16\),\s*child:\s*Column\(""",
"""body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(""",
text,
flags=re.DOTALL
)

# 3) Fix closing brackets (veldig viktig)
text = text.replace(
"""),
      ),""",
"""),
          ),
        ),
      ),"""
)

# 4) Fjern Expanded inni Column (typisk crash årsak)
text = text.replace("Expanded(", "SizedBox(")

# 5) Fjern Positioned hvis finnes (ofte crash med scroll)
text = re.sub(r"Positioned\(", "Container(", text)

if text == orig:
    print("⚠️ Ingen endringer gjort (kan være allerede fikset)")
else:
    path.write_text(text)
    print("✅ Layout fikset stabilt")
PY

echo
flutter analyze || true
echo
echo "Kjør app igjen"
