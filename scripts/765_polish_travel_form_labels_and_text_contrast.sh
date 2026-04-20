#!/usr/bin/env bash
set -euo pipefail

echo "==> 765_polish_travel_form_labels_and_text_contrast"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_765")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 1) Flytt labels litt ned og gjør dem mindre aggressive
text = text.replace(
    """      labelStyle: const TextStyle(
        color: Color(0xFF243940),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF10252B),
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),""",
    """      labelStyle: const TextStyle(
        color: Color(0xFF4A5F67),
        fontWeight: FontWeight.w700,
        fontSize: 13,
        height: 1.1,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF31484F),
        fontWeight: FontWeight.w700,
        fontSize: 13,
        height: 1.1,
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 22, 18, 16),"""
)

# 2) Gjør feltverdier litt mindre/store mindre tunge
text = text.replace(
    """style: const TextStyle(
                        color: Color(0xFF10252B),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),""",
    """style: const TextStyle(
                        color: Color(0xFF10252B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),"""
)

# 3) Samme for dropdown items hvis noen fortsatt er 18/w800
text = text.replace(
    """style: const TextStyle(
                                  color: Color(0xFF10252B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),""",
    """style: const TextStyle(
                                  color: Color(0xFF10252B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),"""
)

text = text.replace(
    """style: const TextStyle(
                                      color: Color(0xFF10252B),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),""",
    """style: const TextStyle(
                                      color: Color(0xFF10252B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),"""
)

# 4) Mørkere hjelpetekster under budsjett / saldo / butikkseksjoner
text = text.replace(
    "color: const Color(0xFF243940),",
    "color: const Color(0xFF334A52),"
)

# Men la hovedtekster være mørke og tydelige
text = text.replace(
    "color: const Color(0xFF334A52),\n                              fontWeight: FontWeight.w700,",
    "color: const Color(0xFF10252B),\n                              fontWeight: FontWeight.w700,"
)

# 5) Fiks den spesifikke lyse teksten: Gå til \"Kort\" og velg et kort
text = re.sub(
    r"Text\(\s*cardLabel,\s*style:\s*Theme\.of\(context\)\.textTheme\.bodyMedium\?\.copyWith\(\s*color:\s*const Color\(0xFF10252B\),\s*fontWeight:\s*FontWeight\.w700,\s*\),\s*\)",
    """Text(
                      cardLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF4A5F67),
                            fontWeight: FontWeight.w600,
                          ),
                    )""",
    text,
    flags=re.DOTALL,
)

# fallback hvis cardLabel står uten samme eksakte spacing
text = text.replace(
    """Text(
                      cardLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF10252B),
                            fontWeight: FontWeight.w700,
                          ),
                    )""",
    """Text(
                      cardLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF4A5F67),
                            fontWeight: FontWeight.w600,
                          ),
                    )"""
)

# 6) Gjør poengplan-tekst mørkere og mer lesbar
text = text.replace(
    """style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF10252B),
                              fontWeight: FontWeight.w700,
                            ),""",
    """style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF2A3D44),
                              fontWeight: FontWeight.w700,
                            ),"""
)

text = text.replace(
    """style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10252B),
                            ),""",
    """style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10252B),
                            ),"""
)

text = text.replace(
    """style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10252B),
                            ),""",
    """style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10252B),
                            ),"""
)

# 7) Litt mer høyde i poengplan-kortet slik at teksten ikke ser klemt ut
text = text.replace(
    "padding: const EdgeInsets.all(20),",
    "padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),"
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
