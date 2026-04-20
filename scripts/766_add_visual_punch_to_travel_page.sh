#!/usr/bin/env bash
set -euo pipefail

echo "==> 766_add_visual_punch_to_travel_page"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_766")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 1) Reiseprofil: gjør hele blokken tydeligere og mer premium
text = text.replace(
"""              _travelLightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reiseprofil',
                      style: _travelSectionTitleStyle(context),
                    ),""",
"""              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF7FBFD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCE7ED)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reiseprofil',
                        style: _travelSectionTitleStyle(context).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),"""
)

# 2) Inputfeltene: mørkere, renere, mer premium
text = text.replace(
"fillColor: const Color(0xFFF4F7FB),",
"fillColor: const Color(0xFF071B34),"
)

text = text.replace(
"color: Color(0xFF4A5F67),",
"color: Color(0xFFD4E2EA),"
)

text = text.replace(
"color: Color(0xFF31484F),",
"color: Color(0xFFEAF4F8),"
)

text = text.replace(
"borderSide: const BorderSide(color: Color(0xFFD9E3EE), width: 1),",
"borderSide: const BorderSide(color: Color(0xFF284764), width: 1.1),"
)

text = text.replace(
"borderSide: const BorderSide(color: Color(0xFF8FB8C5), width: 1.3),",
"borderSide: const BorderSide(color: Color(0xFF5ED0E0), width: 1.5),"
)

# 3) Gjør tekst i felt litt mindre, men skarpere
text = text.replace(
"fontSize: 16,\n                        fontWeight: FontWeight.w700,",
"fontSize: 15,\n                        fontWeight: FontWeight.w800,"
)

# 4) Bonuspartnere: mer eksklusiv blokk
text = text.replace(
"""              Card(
                color: const Color(0xFF0F2C33),""",
"""              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF071E2B),
                      Color(0xFF0F3440),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1E5560), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),"""
)

text = text.replace(
"style: _travelSectionBodyStyle(context).copyWith(",
"style: _travelSectionBodyStyle(context).copyWith("
)

text = text.replace(
"color: Colors.white.withOpacity(0.88),",
"color: const Color(0xFFD8EDF2),"
)

# 5) Slik tenker planen: skarpere og tydeligere
text = text.replace(
"""                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF245B88),
                              Color(0xFF4FC3D9),
                            ],""",
"""                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF113E7A),
                              Color(0xFF0E8FA6),
                            ],"""
)

# 6) Butikkforslag-blokk: mer punch
text = text.replace(
"""              _travelLightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [""",
"""              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D6B73),
                      Color(0xFF0A9098),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [""",
1
)

text = text.replace(
"style: _travelSectionTitleStyle(context).copyWith(fontSize: 18),",
"style: _travelSectionTitleStyle(context).copyWith(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w900),"
)

text = text.replace(
"style: _travelSectionBodyStyle(context),",
"style: _travelSectionBodyStyle(context).copyWith(color: const Color(0xFFE7FBFC), fontWeight: FontWeight.w700),"
)

text = text.replace(
"icon: const Icon(Icons.refresh, color: Color(0xFF7B8D97)),",
"icon: const Icon(Icons.refresh, color: Colors.white),"
)

text = text.replace(
"fontWeight: FontWeight.w800,\n                                    color: const Color(0xFF10252B),",
"fontWeight: FontWeight.w800,\n                                    color: Colors.white,"
)

# 7) Kortene inni butikkforslag: mer premium cards
text = text.replace(
"color: const Color(0xFFF8FBFD),",
"color: const Color(0xFFFFFFFF),"
)

text = text.replace(
"border: Border.all(color: const Color(0xFFE0E7EC)),",
"border: Border.all(color: const Color(0xFFB8D8DC), width: 1.1),"
)

text = text.replace(
"fontSize: 17,",
"fontSize: 18,"
)

# 8) Poengplan: gjør den til et ekte highlight-kort
text = text.replace(
"""              Card(
                color: const Color(0xFFF2E4B9),""",
"""              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFE9A8),
                      Color(0xFFF6D772),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),"""
)

text = text.replace(
"fontWeight: FontWeight.w800,\n                              color: const Color(0xFF10252B),",
"fontWeight: FontWeight.w900,\n                              color: const Color(0xFF10252B),"
)

# 9) Gjør svak tekst i poengplan mørkere
text = text.replace(
"color: const Color(0xFF2A3D44),",
"color: const Color(0xFF20353D),"
)

text = text.replace(
"color: const Color(0xFF4A5F67),",
"color: const Color(0xFF3A4F57),"
)

# 10) Reiseverdi akkurat nå: litt mer premium badge/card
text = text.replace(
"fontWeight: FontWeight.bold,",
"fontWeight: FontWeight.w900,"
)

if text == orig:
    print("Ingen endringer gjort.")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ Patched: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
