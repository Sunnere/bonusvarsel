#!/usr/bin/env bash
set -euo pipefail

echo "==> 712_fix_eb_shopping_root_body_overflow"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/eb_shopping_page.dart")
if not path.exists():
    print("ERROR: lib/pages/eb_shopping_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_712")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

needle = "body: Column("
idx = text.find(needle)

if idx == -1:
    print("ERROR: Fant ikke 'body: Column(' i eb_shopping_page.dart")
    raise SystemExit(1)

near = text[max(0, idx - 300): idx + 700]
if "LayoutBuilder(" in near and "SingleChildScrollView(" in near and "ConstrainedBox(" in near:
    print("body ser allerede wrappet ut. Ingen endring gjort.")
    raise SystemExit(0)

replacement = """body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column("""

text = text[:idx] + replacement + text[idx + len(needle):]

# Finn matchende slutt for Column( som nå ligger inne i replacement
start = idx + len("""body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: """)

i = start
depth = 0
in_single = False
in_double = False
in_triple_single = False
in_triple_double = False
escape = False

while i < len(text):
    ch = text[i]

    if escape:
        escape = False
        i += 1
        continue

    if ch == "\\" and (in_single or in_double or in_triple_single or in_triple_double):
        escape = True
        i += 1
        continue

    if not in_double and not in_triple_single and not in_triple_double and text[i:i+3] == "'''":
        in_triple_single = not in_triple_single
        i += 3
        continue

    if not in_single and not in_triple_single and not in_triple_double and text[i:i+3] == '"""':
        in_triple_double = not in_triple_double
        i += 3
        continue

    if not in_triple_single and not in_triple_double:
        if ch == "'" and not in_double:
            in_single = not in_single
            i += 1
            continue
        if ch == '"' and not in_single:
            in_double = not in_double
            i += 1
            continue

    if in_single or in_double or in_triple_single or in_triple_double:
        i += 1
        continue

    if ch == "(":
        depth += 1
    elif ch == ")":
        depth -= 1
        if depth == 0:
            insert_at = i + 1
            text = (
                text[:insert_at]
                + """
            ),
          ),
        ),
      )"""
                + text[insert_at:]
            )
            break

    i += 1
else:
    print("ERROR: Klarte ikke å finne slutt på body Column(...).")
    raise SystemExit(1)

# Rydd opp overflødige blanklinjer
text = re.sub(r"\n{3,}", "\n\n", text)

if text == original:
    print("Ingen endring skrevet.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 712 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
