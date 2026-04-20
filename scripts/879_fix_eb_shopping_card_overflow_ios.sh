#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_879.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

# 1) Gi tittel i AppBar litt mindre font og ellipsis-vennlig
text = text.replace(
"""          child: Text('EuroBonus Shopping', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
""",
"""          child: const Text(
            'EuroBonus Shopping',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
""",
1)

# 2) Gjør header-tekst litt mer kompakt
text = text.replace(
"""                  'Finn butikker, kampanjer og poengboost',
""",
"""                  'Finn butikker, kampanjer og poengboost',
""",
1)

# 3) Forkort "Gratis vs Premium" til "Gratis / Premium" i headerlink
text = text.replace(
"""                            'Gratis vs Premium',
""",
"""                            'Gratis / Premium',
""",
1)

# 4) Gjør source-filter-label litt kortere hvis den finnes
text = text.replace("Sortér: høy rate", "Høy rate")

# 5) Fiks den vanligste overflow-teksten i kortene
text = text.replace("Boost – oppgrader", "Boost")
text = text.replace("Boost - oppgrader", "Boost")

# 6) Gjør Basis-badge kortere hvis den finnes flere steder
# behold Basis hvis det brukes, men kortere label kan være nødvendig
# ingen endring her siden Basis allerede er kort.

# 7) Finn vanlige Row-blokker med butikknavn + badge + icon og gjør tittel flexbar
old = """                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 12),
                        Text(
"""

new = """                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
"""

if old in text:
    text = text.replace(old, new, 1)

old2 = """                        ),
"""

new2 = """                          ),
                        ),
"""

# bytt kun første forekomst etter ovenstående transformasjon
idx = text.find("Expanded(\n                          child: Text(")
if idx != -1:
    tail = text[idx:]
    pos = tail.find("                        ),\n")
    if pos != -1:
        absolute = idx + pos
        text = text[:absolute] + "                          ),\n                        ),\n" + text[absolute + len("                        ),\n"):]

# 8) Hvis badge + ekstern ikon står i en Row uten wrap, gjør den mer robust
text = text.replace(
"""                      Row(
                        mainAxisSize: MainAxisSize.min,
""",
"""                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
""")

# 9) Reduser litt horisontal padding i kort hvis den finnes
text = text.replace(
"padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),",
"padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),"
)

if text == orig:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn mobil-fix for shopping-kort overflow")
PY

flutter analyze
echo "✅ 879 ferdig"
