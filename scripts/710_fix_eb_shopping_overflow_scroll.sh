#!/usr/bin/env bash
set -euo pipefail

echo "==> 710_fix_eb_shopping_overflow_scroll"

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
bak = path.with_name(path.name + f".bak_{stamp}_710")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()

if "SingleChildScrollView(\n" in text and "eb_shopping_page.dart" in str(path):
    print("Looks like page may already contain a scroll wrapper. Continuing with targeted check...")

lines = text.splitlines()
target_line_no = 754
target_idx = max(0, min(len(lines) - 1, target_line_no - 1))

# Finn nærmeste Column( rundt den linjen som Flutter pekte på.
column_line_idx = None
search_start = max(0, target_idx - 40)
search_end = min(len(lines), target_idx + 40)

for i in range(search_start, search_end):
    if "Column(" in lines[i]:
        column_line_idx = i
        break

if column_line_idx is None:
    # fallback: finn første body: ... Column(
    for i in range(len(lines)):
        if "body:" in lines[i]:
            for j in range(i, min(len(lines), i + 40)):
                if "Column(" in lines[j]:
                    column_line_idx = j
                    break
            if column_line_idx is not None:
                break

if column_line_idx is None:
    print("ERROR: Could not find target Column(...) to wrap.")
    raise SystemExit(1)

column_line = lines[column_line_idx]
column_pos_in_line = column_line.find("Column(")
abs_pos = sum(len(l) + 1 for l in lines[:column_line_idx]) + column_pos_in_line

if "SingleChildScrollView(" in text[max(0, abs_pos - 250):abs_pos + 250]:
    print("Target Column already appears to be wrapped. No change made.")
    raise SystemExit(0)

# Wrap start
replacement = (
    "SingleChildScrollView(\n"
    "                padding: const EdgeInsets.only(bottom: 16),\n"
    "                child: Column("
)
text = text[:abs_pos] + replacement + text[abs_pos + len("Column("):]

# Finn matching ')' for Column( fra ny posisjon
start = abs_pos + len("SingleChildScrollView(\n                padding: const EdgeInsets.only(bottom: 16),\n                child: ")
i = start
depth = 0
in_single = False
in_double = False
in_triple_single = False
in_triple_double = False
escape = False

while i < len(text):
    ch = text[i]
    nxt3 = text[i:i+3]

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
            text = text[:insert_at] + "\n                )" + text[insert_at:]
            break

    i += 1
else:
    print("ERROR: Could not match the target Column(...) parentheses.")
    raise SystemExit(1)

# Litt ekstra rydding
text = re.sub(r"\n{3,}", "\n\n", text)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 710 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
