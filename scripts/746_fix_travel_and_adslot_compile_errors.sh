#!/usr/bin/env bash
set -euo pipefail

echo "==> 746_fix_travel_and_adslot_compile_errors"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

def backup(path_str: str, tag: str):
    p = Path(path_str)
    if p.exists():
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        bak = p.with_name(p.name + f".bak_{stamp}_{tag}")
        shutil.copy2(p, bak)
        print(f"Backup: {bak}")

# --- Fix travel_page.dart ---
travel = Path("lib/pages/travel_page.dart")
if travel.exists():
    text = travel.read_text()
    original = text

    text = text.replace(
        "if (key.contains('bærum energi') or key.contains('baerum energi'))",
        "if (key.contains('bærum energi') || key.contains('baerum energi'))",
    )

    if text != original:
        backup(str(travel), "746")
        travel.write_text(text)
        print("Patched: lib/pages/travel_page.dart")
    else:
        print("No changes needed in lib/pages/travel_page.dart")
else:
    print("WARNING: lib/pages/travel_page.dart not found")

# --- Fix ad_slot.dart duplicate mainAxisSize ---
adslot = Path("lib/widgets/ad_slot.dart")
if adslot.exists():
    text = adslot.read_text()
    original = text

    # Fjern duplikate mainAxisSize i samme Column-kall
    pattern = re.compile(
        r"(Column\(\s*mainAxisSize:\s*MainAxisSize\.min,\s*)(.*?)(\s*mainAxisSize:\s*MainAxisSize\.min,\s*)",
        re.DOTALL
    )
    text = re.sub(pattern, r"\1\2", text)

    # Ekstra sikkerhet: hvis en Column har samme named arg to ganger, behold første
    pattern2 = re.compile(
        r"(Column\((?:(?!Column\().)*?mainAxisSize:\s*MainAxisSize\.min,)(?P<body>(?:(?!Column\().)*?)mainAxisSize:\s*MainAxisSize\.min,",
        re.DOTALL
    )
    text = re.sub(pattern2, r"\1\g<body>", text)

    if text != original:
        backup(str(adslot), "746")
        adslot.write_text(text)
        print("Patched: lib/widgets/ad_slot.dart")
    else:
        print("No changes needed in lib/widgets/ad_slot.dart")
else:
    print("WARNING: lib/widgets/ad_slot.dart not found")
PY

echo
echo "✅ 746 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
