#!/usr/bin/env bash
set -euo pipefail

echo "==> 774_upgrade_travel_page_to_premium_level"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_774")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 1) Input-feltene: mørkere premium navy + bedre kontrast
text = text.replace(
    "fillColor: const Color(0xFF071B34),",
    "fillColor: const Color(0xFF06182D),"
)
text = text.replace(
    "color: Color(0xFFD6E5EE),",
    "color: Color(0xFFCFE0EA),"
)
text = text.replace(
    "color: Color(0xFFEAF5FA),",
    "color: Color(0xFFF6FBFD),"
)
text = text.replace(
    "color: Color(0xFF8FA8B7),",
    "color: Color(0xFF9AB3C0),"
)
text = text.replace(
    "borderSide: const BorderSide(color: Color(0xFF254765), width: 1.1),",
    "borderSide: const BorderSide(color: Color(0xFF1F4465), width: 1.15),"
)
text = text.replace(
    "borderSide: const BorderSide(color: Color(0xFF58D0E0), width: 1.5),",
    "borderSide: const BorderSide(color: Color(0xFF67D7E6), width: 1.7),"
)

# 2) Liten premium-tuning av label-posisjon
text = text.replace(
    "contentPadding: const EdgeInsets.fromLTRB(18, 26, 18, 12),",
    "contentPadding: const EdgeInsets.fromLTRB(18, 27, 18, 13),"
)
text = text.replace(
    "contentPadding: const EdgeInsets.fromLTRB(18, 24, 18, 14),",
    "contentPadding: const EdgeInsets.fromLTRB(18, 27, 18, 13),"
)

# 3) Estimat/0 poeng: ekte highlight
text = text.replace(
    "fontSize: 32,",
    "fontSize: 34,"
)
text = text.replace(
    "fontSize: 30,",
    "fontSize: 34,"
)
text = text.replace(
    "color: const Color(0xFF0F8B8D),",
    "color: const Color(0xFF0A8FA3),"
)
text = text.replace(
    "color: const Color(0xFF0A6E78),",
    "color: const Color(0xFF0A8FA3),"
)
text = text.replace(
    "fontWeight: FontWeight.w900,",
    "fontWeight: FontWeight.w900,\n                              letterSpacing: -0.3,"
)

# 4) Foreløpig estimat-label sterkere
text = text.replace(
    "color: const Color(0xFF2B474F),",
    "color: const Color(0xFF243B42),"
)
text = text.replace(
    "color: const Color(0xFF35515A),",
    "color: const Color(0xFF243B42),"
)

# 5) Poengplan-kort: mer premium gold
text = text.replace(
    "color: const Color(0xFFF2E3BE),",
    "color: const Color(0xFFF3E1A6),"
)
text = text.replace(
    "color: const Color(0xFF6C7178),",
    "color: const Color(0xFF5A6168),"
)
text = text.replace(
    "color: const Color(0xFF546870),",
    "color: const Color(0xFF4A5A61),"
)

# 6) Reiseprofil / hvite kort litt mer premium med tydeligere kant
text = text.replace(
    "side: const BorderSide(color: Color(0xFFE1E9EE), width: 1.1),",
    "side: const BorderSide(color: Color(0xFFD9E4EA), width: 1.15),"
)
text = text.replace(
    "borderRadius: BorderRadius.circular(22),",
    "borderRadius: BorderRadius.circular(24),"
)

# 7) Butikkforslag-kort: mer luksus i mørk topp
text = text.replace(
    "padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),",
    "padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),",
    1
)
text = text.replace(
    "fontWeight: FontWeight.w800,\n                                              color: _textDark,",
    "fontWeight: FontWeight.w900,\n                                              color: _textDark,"
)
text = text.replace(
    "color: const Color(0xFF243E46),",
    "color: const Color(0xFF1F3941),"
)
text = text.replace(
    "color: const Color(0xFF2E4951),",
    "color: const Color(0xFF52656D),"
)

# 8) Hjelpetekster mørkere
text = text.replace(
    "Color(0xFF4F636B)",
    "Color(0xFF4A5D65)"
)
text = text.replace(
    "Color(0xFF60747C)",
    "Color(0xFF4A5D65)"
)

# 9) CardLabel under budsjett litt skarpere
text = text.replace(
    "color: const Color(0xFF465B63),",
    "color: const Color(0xFF42575F),"
)

# 10) Gjør lagret-poeng-tekst mer elegant
text = text.replace(
    "color: const Color(0xFF7A8C94),",
    "color: const Color(0xFF667981),"
)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ Premium-oppgradering skrevet til: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
