#!/usr/bin/env bash
set -euo pipefail

echo "==> 772_remove_extra_closing_brackets_after_storetypes"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_772")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

bad = """                      ],
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TravelValueCard(
"""

good = """                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              TravelValueCard(
"""

if bad not in text:
    print("❌ Fant ikke eksakt ødelagt blokk.")
    print("Kjør og send:")
    print('  sed -n "1288,1318p" lib/pages/travel_page.dart')
    raise SystemExit(1)

text = text.replace(bad, good, 1)

path.write_text(text)
print(f"✅ Reparerte ekstra avslutninger i: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
