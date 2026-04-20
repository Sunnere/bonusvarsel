#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/onboarding_page.dart"
STAMP="$(date +%Y%m%d-%H%M%S)"

cp "$FILE" "${FILE}.bak.${STAMP}"
echo "Backup laget: ${FILE}.bak.${STAMP}"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/onboarding_page.dart")
src = path.read_text()

# Finn Scaffold body og wrap med scroll
pattern = r"return Scaffold\(\s*body:\s*PageView\((.*?)\)\s*\);"

replacement = """return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: PageView(\\1),
                ),
              ),
            );
          },
        ),
      ),
    );"""

new_src, count = re.subn(pattern, replacement, src, flags=re.S)

if count == 0:
    print("Fant ikke PageView-blokk – ingen endring gjort")
    exit(1)

path.write_text(new_src)
print("Fixet overflow i onboarding_page.dart")
PY

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter test"
