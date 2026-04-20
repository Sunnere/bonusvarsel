#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/home_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_870.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/home_page.dart")
text = p.read_text()
original = text

# 1) import
if "bonusvarsel_alerts_page.dart" not in text:
    import_candidates = [
        "import 'travel_page.dart';\n",
        'import "travel_page.dart";\n',
        "import 'premium_page.dart';\n",
        'import "premium_page.dart";\n',
    ]
    inserted = False
    for marker in import_candidates:
        if marker in text:
            text = text.replace(
                marker,
                marker + "import 'bonusvarsel_alerts_page.dart';\n",
                1,
            )
            inserted = True
            break
    if not inserted:
        # fallback: legg etter siste import-linje
        m = list(re.finditer(r"^import .+;\n", text, flags=re.MULTILINE))
        if not m:
            raise SystemExit("❌ Fant ingen imports å sette alerts-import etter")
        last = m[-1]
        insert_pos = last.end()
        text = text[:insert_pos] + "import 'bonusvarsel_alerts_page.dart';\n" + text[insert_pos:]

# 2) legg til BonusvarselAlertsPage i første liste med const sider
page_list_patterns = [
    (
        r"(\[\s*const [^\]]+?\])",
        "page_list",
    ),
]

added_page = False

# mer presis: finn første forekomst av en liste som ser ut som sidewidgets
m = re.search(
    r"(\[\s*const\s+[A-Za-z0-9_]+Page\(\)\s*,.*?\])",
    text,
    flags=re.DOTALL,
)
if m and "BonusvarselAlertsPage()" not in m.group(1):
    block = m.group(1)
    new_block = block[:-1] + ",\n    const BonusvarselAlertsPage(),\n  ]"
    text = text.replace(block, new_block, 1)
    added_page = True

# fallback hvis over ikke traff
if not added_page and "BonusvarselAlertsPage()" not in text:
    m2 = re.search(
        r"(final\s+\w+\s*=\s*\[\s*const\s+[A-Za-z0-9_]+Page\(\)\s*,.*?\];)",
        text,
        flags=re.DOTALL,
    )
    if m2:
        block = m2.group(1)
        new_block = block.replace("];", "  const BonusvarselAlertsPage(),\n];", 1)
        text = text.replace(block, new_block, 1)
        added_page = True

# 3) legg til NavigationDestination for Varsler
if "label: 'Varsler'" not in text and 'label: "Varsler"' not in text:
    nav_match = re.search(
        r"(destinations\s*:\s*\[.*?\])",
        text,
        flags=re.DOTALL,
    )
    if nav_match:
        block = nav_match.group(1)
        insertion = """
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Varsler',
          ),
"""
        new_block = block[:-1] + insertion + "\n        ]"
        text = text.replace(block, new_block, 1)
    else:
        # fallback: finn NavigationBar( ... [ ... ] )
        nav_match2 = re.search(
            r"(NavigationBar\s*\(.*?destinations\s*:\s*\[.*?\])",
            text,
            flags=re.DOTALL,
        )
        if nav_match2:
            block = nav_match2.group(1)
            insertion = """
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Varsler',
          ),
"""
            new_block = block[:-1] + insertion + "\n        ]"
            text = text.replace(block, new_block, 1)
        else:
            raise SystemExit("❌ Fant ikke destinations-lista i NavigationBar")

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Forsøkte å legge Alerts inn i home navigation")
PY

flutter analyze
echo "✅ 870 ferdig"
