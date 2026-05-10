#!/bin/bash
set -e

python3 << 'PYEOF'
path = "/Users/sunnerehelse/bonusvarsel/lib/pages/travel_page.dart"
with open(path, "r") as f:
    content = f.read()

old = """      controller: _sasPointsCtrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Color(0xFF162E35),
        fontWeight: FontWeight.w800,
      ),"""

new = """      controller: _sasPointsCtrl,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      style: const TextStyle(
        color: Color(0xFF162E35),
        fontWeight: FontWeight.w800,
      ),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Done-knapp lagt til på poengfeltet")
else:
    print("❌ Fant ikke riktig tekstfelt – sjekk manuelt")

with open(path, "w") as f:
    f.write(content)
PYEOF
