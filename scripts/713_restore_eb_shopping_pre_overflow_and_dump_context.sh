#!/usr/bin/env bash
set -euo pipefail

echo "==> 713_restore_eb_shopping_pre_overflow_and_dump_context"

mkdir -p .tmp_ai

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import glob

page = Path("lib/pages/eb_shopping_page.dart")
if not page.exists():
    print("ERROR: lib/pages/eb_shopping_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
current_bak = page.with_name(page.name + f".bak_{stamp}_713")
shutil.copy2(page, current_bak)
print(f"Backup current file: {current_bak}")

# Foretrekk backup fra 708, siden appen åpnet da og vi bare hadde gul stripe.
candidates = sorted(glob.glob("lib/pages/eb_shopping_page.dart.bak_*_708"))
fallbacks = sorted(glob.glob("lib/pages/eb_shopping_page.dart.bak_*"))

restore_from = None
if candidates:
    restore_from = candidates[-1]
else:
    # unngå å restore fra 710/711/712 hvis mulig
    filtered = [p for p in fallbacks if not any(s in p for s in ["_710", "_711", "_712", "_713"])]
    if filtered:
        restore_from = filtered[-1]

if restore_from:
    shutil.copy2(restore_from, page)
    print(f"Restored stable baseline from: {restore_from}")
else:
    print("No suitable restore backup found. Leaving current file as-is.")

text = page.read_text()
lines = text.splitlines()

def block(start, end):
    out = []
    start = max(1, start)
    end = min(len(lines), end)
    for i in range(start, end + 1):
        out.append(f"{i:5d}: {lines[i-1]}")
    return "\n".join(out)

# Finn nyttig kontekst
targets = []
for needle in ["Scaffold(", "body:", "Column(", "SingleChildScrollView(", "Expanded(", "Flexible("]:
    for i, line in enumerate(lines, start=1):
        if needle in line:
            targets.append((needle, i))
            break

with open(".tmp_ai/eb_shopping_overflow_context.txt", "w") as f:
    f.write("=== FILE ===\n")
    f.write(str(page) + "\n\n")

    f.write("=== FIRST MATCHES ===\n")
    for needle, lineno in targets:
        f.write(f"{needle} -> line {lineno}\n")
    f.write("\n")

    f.write("=== AROUND REPORTED OVERFLOW AREA (720-790) ===\n")
    f.write(block(720, 790))
    f.write("\n\n")

    f.write("=== AROUND 790-860 ===\n")
    f.write(block(790, 860))
    f.write("\n\n")

    # også første scaffold/body-blokk
    scaffold_line = next((i for i, line in enumerate(lines, start=1) if "Scaffold(" in line), None)
    if scaffold_line:
        f.write("=== AROUND FIRST SCAFFOLD ===\n")
        f.write(block(scaffold_line - 20, scaffold_line + 120))
        f.write("\n\n")

print("Wrote: .tmp_ai/eb_shopping_overflow_context.txt")
PY

echo
echo "Kjører analyze etter restore..."
flutter analyze || true

echo
echo "----- CONTEXT START -----"
sed -n '1,260p' .tmp_ai/eb_shopping_overflow_context.txt
echo "----- CONTEXT END -----"
echo
echo "Neste:"
echo "  flutter run -d macos"
