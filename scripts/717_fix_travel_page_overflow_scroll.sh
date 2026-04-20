#!/usr/bin/env bash
set -euo pipefail

echo "==> 717_fix_travel_page_overflow_scroll"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_717")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

old = """      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ["""

new = """      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ["""

if old not in text:
    print("ERROR: expected body block not found")
    raise SystemExit(1)

text = text.replace(old, new, 1)

old_tail = """            ],
          ),
        ),
      ),"""

new_tail = """            ],
          ),
        ),
      ),"""

# No structural tail change needed beyond removing the extra Padding layer.
# Replace the first matching closing sequence for that block.
idx = text.find(old_tail)
if idx == -1:
    print("ERROR: expected body closing block not found")
    raise SystemExit(1)

text = text.replace(old_tail, new_tail, 1)

if text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 717 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
