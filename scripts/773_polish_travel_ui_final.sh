#!/usr/bin/env bash
set -euo pipefail

echo "==> 773_polish_travel_ui_final"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_773")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 1. Litt mer visuell sentrering av label i felter
text = text.replace(
    "contentPadding: const EdgeInsets.fromLTRB(18, 24, 18, 14),",
    "contentPadding: const EdgeInsets.fromLTRB(18, 26, 18, 12),"
)

# 2. Boost "0 poeng" (estimat)
text = text.replace(
    "fontSize: 30,",
    "fontSize: 32,"
)

text = text.replace(
    "color: const Color(0xFF0A6E78),",
    "color: const Color(0xFF0F8B8D),"
)

# 3. Gjør label over estimat mer tydelig
text = text.replace(
    "color: const Color(0xFF35515A),",
    "color: const Color(0xFF2B474F),"
)

# 4. Skjul butikkseksjon hvis den ikke har ekte data
if "storeSuggestions.take(5)" in text:
    text = text.replace(
        "for (final s in storeSuggestions.take(5)) ...[",
        "if (storeSuggestions.any((s) => s.title.trim().isNotEmpty))\n                        for (final s in storeSuggestions.take(5)) ...["
    )

# 5. Gjør hjelpetekst litt mørkere (bedre lesbarhet)
text = text.replace(
    "Color(0xFF60747C)",
    "Color(0xFF4F636B)"
)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ UI polert ferdig")
PY

echo
echo "Kjør:"
echo "  flutter run -d macos"
