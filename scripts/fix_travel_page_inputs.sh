#!/bin/bash
set -e

python3 << 'PYEOF'
path = "/Users/sunnerehelse/bonusvarsel/lib/pages/travel_page.dart"
with open(path, "r") as f:
    content = f.read()

# Fix 1: Sett standardverdi til 0 istedenfor 36797
content = content.replace(
    "TextEditingController(text: '36797')",
    "TextEditingController(text: '0')"
)

# Fix 2: Endre hint text
content = content.replace(
    "hintText: 'f.eks 36797'",
    "hintText: 'Skriv inn dine poeng'"
)

with open(path, "w") as f:
    f.write(content)

print("✅ travel_page.dart: standardverdi satt til 0 og hint oppdatert")
PYEOF
