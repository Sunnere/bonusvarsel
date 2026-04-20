#!/usr/bin/env bash
set -euo pipefail

echo "==> 752_fix_travel_page_broken_style_injections"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_752")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Fiks ødelagt _heroTitleStyle-kall:
text = text.replace(
    "style: _heroTitleStyle(context, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),",
    "style: _heroTitleStyle(context).copyWith(fontSize: 18, fontWeight: FontWeight.w800),",
)

# 2) Fjern feil injisert style-fragment som havnet alene på egen linje
text = text.replace(
    ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),",
    "),",
)

# 3) Rydd opp hvis en TextStyle(...) fikk style: stukket inn inni seg
text = re.sub(
    r"TextStyle\((.*?)\,\s*style:\s*const TextStyle\(fontSize:\s*18,\s*fontWeight:\s*FontWeight\.w800\)\)",
    r"TextStyle(\1)",
    text,
    flags=re.DOTALL,
)

# 4) Rydd opp hvis child: Text(...) ble dobbelt-patchet feil
text = re.sub(
    r"child:\s*Text\(([^,\n][^)]*?)\,\s*style:\s*const TextStyle\(fontSize:\s*18,\s*fontWeight:\s*FontWeight\.w800\)\)",
    r"child: Text(\1)",
    text,
)

# 5) Ekstra sikkerhet: fjern tomme ', style:' som står rett før avslutning
text = re.sub(
    r"\n\s*,\s*style:\s*const TextStyle\(fontSize:\s*18,\s*fontWeight:\s*FontWeight\.w800\)\),",
    "\n        ),",
    text,
)

if text == original:
    print("No changes made.")
else:
    path.write_text(text)
    print(f"Patched: {path}")
PY

echo
echo "✅ 752 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
