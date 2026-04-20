#!/usr/bin/env bash
set -euo pipefail

echo "==> 751_fix_travel_page_text_visibility_and_block_sizes"

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
bak = path.with_name(path.name + f".bak_{stamp}_751")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Mørkere tekstfarger
text = text.replace(
    "static const Color _textSoft = Color(0xFF35515A);",
    "static const Color _textSoft = Color(0xFF243940);",
)
text = text.replace(
    "static const Color _textDark = Color(0xFF183038);",
    "static const Color _textDark = Color(0xFF10252B);",
)

# 2) Større poengkort / bedre padding
text = text.replace(
    "padding: const EdgeInsets.all(14),",
    "padding: const EdgeInsets.all(18),"
)

text = text.replace(
    "borderRadius: BorderRadius.circular(18),",
    "borderRadius: BorderRadius.circular(22),"
)

# 3) Gjør poengplan-kortet bredere/tydeligere hvis det finnes som Container/Card med fast liten bredde
text = re.sub(
    r"width:\s*280,",
    "width: double.infinity,",
    text
)

# 4) Gjør sekjsonstitler større
text = text.replace(
    "fontWeight: FontWeight.w800,",
    "fontWeight: FontWeight.w900,\n      fontSize: 22,",
)

# 5) Gjør body-tekst mørkere og mer lesbar
text = text.replace(
    "color: const Color(0xFF1F3941),",
    "color: const Color(0xFF1C3036),",
)
text = text.replace(
    "color: const Color(0xFF2E4951),",
    "color: const Color(0xFF233A41),",
)

# 6) Øk høyde på tekstfelt/dropdowns
text = text.replace(
    "height: 44,",
    "height: 60,",
)

# 7) InputDecoration: større padding, tydeligere labelstil
text = text.replace(
    "contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),",
    "contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),",
)
text = text.replace(
    "filled: true,",
    "filled: true,\n                      labelStyle: TextStyle(\n                        color: Color(0xFF243940),\n                        fontWeight: FontWeight.w700,\n                        fontSize: 15,\n                      ),\n                      floatingLabelStyle: TextStyle(\n                        color: Color(0xFF10252B),\n                        fontWeight: FontWeight.w800,\n                        fontSize: 16,\n                      ),",
)

# 8) Gjør selected text i feltene større
text = re.sub(
    r"child:\s*Text\(([^)]+)\)",
    r"child: Text(\1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))",
    text
)

# 9) Reiseprofil-kort: mer luft
text = text.replace(
    "padding: const EdgeInsets.all(16),",
    "padding: const EdgeInsets.all(20),"
)

# 10) Gjør hele seksjoner mindre trange
text = text.replace(
    "const SizedBox(height: 6),",
    "const SizedBox(height: 10),"
)
text = text.replace(
    "const SizedBox(height: 12),",
    "const SizedBox(height: 16),"
)

# 11) Hvis labels står inne i feltene og blir skjult, legg inn top spacing med ekstra SizedBox etter seksjonstitler
text = text.replace(
    "Text(\n                        'Reiseprofil',",
    "Text(\n                        'Reiseprofil',"
)
text = text.replace(
    "style: _sectionTitleStyle(context),\n                      ),",
    "style: _sectionTitleStyle(context),\n                      ),\n                      const SizedBox(height: 12),",
    1
)

# 12) Gjør den gule poengblokka større og mer synlig
text = text.replace(
    "color: const Color(0xFFF2E3BE),",
    "color: const Color(0xFFF0E1B8),"
)

# 13) For lyse linjer i poengkortet -> mørkere
text = text.replace(
    "color: Colors.white,",
    "color: const Color(0xFF10252B),"
)

# 14) Sikre at små tekstlinjer ikke blir nesten usynlige
text = text.replace(
    "fontWeight: FontWeight.w600,",
    "fontWeight: FontWeight.w700,"
)

if text == original:
    print("No changes made.")
else:
    path.write_text(text)
    print(f"Patched: {path}")
PY

echo
echo "✅ 751 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
