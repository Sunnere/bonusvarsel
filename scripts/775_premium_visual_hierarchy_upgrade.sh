#!/usr/bin/env bash
set -euo pipefail

echo "==> 775_premium_visual_hierarchy_upgrade"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_775")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 1. KPI Poeng (gjør tall mer premium)
text = text.replace(
    "fontSize: 34,",
    "fontSize: 36,"
)

text = text.replace(
    "letterSpacing: -0.3,",
    "letterSpacing: -0.5,"
)

# 2. Gjør chips mer premium (rounded + tydeligere)
text = text.replace(
    "borderRadius: BorderRadius.circular(12)",
    "borderRadius: BorderRadius.circular(18)"
)

# 3. Litt mer luft i butikkliste
text = text.replace(
    "const SizedBox(height: 10),",
    "const SizedBox(height: 12),"
)

# 4. Gjør butikktekst mer premium
text = text.replace(
    "fontWeight: FontWeight.w700,",
    "fontWeight: FontWeight.w800,"
)

# 5. Reiseverdi kort → mer kontrast
text = text.replace(
    "Color(0xFF06182D)",
    "Color(0xFF051526)"
)

# 6. Litt mer luft rundt hovedkort
text = text.replace(
    "padding: const EdgeInsets.all(14),",
    "padding: const EdgeInsets.all(16),"
)

# 7. Hjelpetekst litt mindre (premium look)
text = text.replace(
    "fontWeight: FontWeight.w600,",
    "fontWeight: FontWeight.w500,"
)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ Premium hierarchy upgrade ferdig")
PY

echo
echo "Kjør:"
echo "  flutter run -d macos"
