#!/usr/bin/env bash
set -euo pipefail

echo "==> 743_fix_travel_page_readability_and_contrast"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_743")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Mørkere, tydeligere body-tekst generelt
text = text.replace(
    "static const Color _textSoft = Color(0xFF4F666D);",
    "static const Color _textSoft = Color(0xFF35515A);",
)

# 2) Poengplan-kortet var for utvasket -> gjør mørkere og tydeligere
text = text.replace(
    "color: _sandCard,",
    "color: const Color(0xFFF2E3BE),",
)

# 3) Gjør standard info-tekst på kort mørkere
text = text.replace(
    "style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                        color: const Color(0xFF36535B),",
    "style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                        color: const Color(0xFF1F3941),",
)

text = text.replace(
    "style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                              color: _textSoft,",
    "style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                              color: const Color(0xFF2E4951),",
)

# 4) Gjør undertitler/sekundærtekst i feedkort mørkere
text = text.replace(
    "style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                                              color: const Color(0xFF36535B),\n                                              fontWeight: FontWeight.w600,\n                                            ),",
    "style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                                              color: const Color(0xFF243E46),\n                                              fontWeight: FontWeight.w700,\n                                            ),",
)

# 5) Mer lesbar tekst på poengkortet
text = text.replace(
    "style: Theme.of(context).textTheme.bodyLarge?.copyWith(\n                              fontWeight: FontWeight.w700,\n                            ),",
    "style: Theme.of(context).textTheme.bodyLarge?.copyWith(\n                              fontWeight: FontWeight.w800,\n                              color: const Color(0xFF183038),\n                            ),",
)

text = text.replace(
    "style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                              fontWeight: FontWeight.w700,\n                            ),",
    "style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                              fontWeight: FontWeight.w800,\n                              color: const Color(0xFF183038),\n                            ),",
)

# 6) Bedre overlay på bildekort
old_needtile_image = """              child: Image.asset(
                _assetForNeed(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1B6B73),
                          Color(0xFF0F3D5E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.luggage,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  );
                },
              ),"""

new_needtile_image = """              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _assetForNeed(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1B6B73),
                              Color(0xFF0F3D5E),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.luggage,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x22000000),
                          Color(0x44000000),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),"""

text = text.replace(old_needtile_image, new_needtile_image)

# 7) Gjør title i pakkeliste enda tydeligere
text = text.replace(
    "fontWeight: FontWeight.w800,\n                        color: const Color(0xFF183038),",
    "fontWeight: FontWeight.w900,\n                        color: const Color(0xFF142D34),",
)

# 8) Feed-kortene: litt mørkere tekst på hvit bakgrunn
text = text.replace(
    "Text(item.description!,",
    "Text(\n                                          item.description!,",
)
text = text.replace(
    "style: Theme.of(context).textTheme.bodySmall,",
    "style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                                              color: const Color(0xFF28424A),\n                                              fontWeight: FontWeight.w600,\n                                            ),",
)

# 9) Reiseprofil-inputs fortsatt litt tunge visuelt, men behold foreløpig. Gjør labeltekst tydeligere rundt feltene.
text = re.sub(
    r"labelText: '([^']+)'",
    lambda m: f"labelText: '{m.group(1)}'",
    text
)

# 10) Rydd
text = re.sub(r"\n{3,}", "\n\n", text)

if text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 743 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
