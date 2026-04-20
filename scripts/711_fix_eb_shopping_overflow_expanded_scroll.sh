#!/usr/bin/env bash
set -euo pipefail

echo "==> 711_fix_eb_shopping_overflow_expanded_scroll"

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
bak = path.with_name(path.name + f".bak_{stamp}_711")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text
lines = text.splitlines()

TARGET_LINE = 754
target_idx = max(0, min(len(lines) - 1, TARGET_LINE - 1))

def line_start_offset(lines, idx):
    return sum(len(l) + 1 for l in lines[:idx])

# Finn nærmeste "Column(" rundt linjen Flutter meldte
column_idx = None
for radius in range(0, 80):
    lo = max(0, target_idx - radius)
    hi = min(len(lines) - 1, target_idx + radius)
    for i in range(lo, hi + 1):
        if "Column(" in lines[i]:
            column_idx = i
            break
    if column_idx is not None:
        break

if column_idx is None:
    print("ERROR: Could not find Column(...) near target line.")
    raise SystemExit(1)

column_line = lines[column_idx]
col_pos = column_line.find("Column(")
abs_pos = line_start_offset(lines, column_idx) + col_pos

nearby = text[max(0, abs_pos - 400):abs_pos + 400]
if "Expanded(" in nearby and "SingleChildScrollView(" in nearby:
    print("Target area already appears wrapped with Expanded + SingleChildScrollView. No change made.")
    raise SystemExit(0)

# Bytt Column( -> Expanded(child: SingleChildScrollView(... child: Column(
replacement = (
    "Expanded(\n"
    "              child: SingleChildScrollView(\n"
    "                padding: const EdgeInsets.only(bottom: 24),\n"
    "                child: Column("
)
text = text[:abs_pos] + replacement + text[abs_pos + len("Column("):]

# Finn matching ) for denne Column(
start_search = abs_pos + len(
    "Expanded(\n"
    "              child: SingleChildScrollView(\n"
    "                padding: const EdgeInsets.only(bottom: 24),\n"
    "                child: "
)

i = start_search
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
            text = text[:insert_at] + "\n                ),\n              ),\n            " + text[insert_at:]
            break

    i += 1
else:
    print("ERROR: Could not match Column(...) parentheses.")
    raise SystemExit(1)

# Litt opprydding av overflødige blanklinjer
text = re.sub(r"\n{3,}", "\n\n", text)

if text == original:
    print("No changes written.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 711 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
