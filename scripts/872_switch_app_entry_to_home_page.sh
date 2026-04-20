#!/usr/bin/env bash
set -euo pipefail

FILE="lib/main.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_872.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/main.dart")
text = p.read_text()
original = text

if "package:bonusvarsel/pages/home_page.dart" not in text:
    old_import = "import 'package:bonusvarsel/pages/eb_shopping_page.dart';\n"
    new_import = old_import + "import 'package:bonusvarsel/pages/home_page.dart';\n"
    if old_import not in text:
        raise SystemExit("❌ Fant ikke importen til eb_shopping_page.dart")
    text = text.replace(old_import, new_import, 1)

old_home = "      home: const EbShoppingPage(),\n"
new_home = "      home: const HomePage(),\n"

if old_home not in text:
    raise SystemExit("❌ Fant ikke home: const EbShoppingPage(),")

text = text.replace(old_home, new_home, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Byttet app-entry fra EbShoppingPage til HomePage")
PY

flutter analyze
echo "✅ 872 ferdig"
