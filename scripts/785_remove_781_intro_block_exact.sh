#!/usr/bin/env bash
set -euo pipefail

echo "==> 785_remove_781_intro_block_exact"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_785")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

block = """
          // 🔥 INTRO
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF7F8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Familietur-planlegger',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Planlegg familiebehov, estimer poeng og finn hvilke kjøp som gir mest verdi.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
"""

if block in text:
    text = text.replace(block, "", 1)
    path.write_text(text)
    print("✅ Fjernet 781-introblokken eksakt.")
    raise SystemExit(0)

print("⚠️ Eksakt blokk ikke funnet. Prøver liten fallback rundt teksten...")

start_anchor = "Familietur-planlegger"
end_anchor = "Bonusprogram"

s = text.find(start_anchor)
e = text.find(end_anchor, s if s != -1 else 0)

if s == -1 or e == -1:
    print("❌ Fant ikke ankertekstene. Kjør dette og send resultatet:")
    print("  sed -n '120,220p' lib/pages/travel_page.dart")
    raise SystemExit(1)

container_start = text.rfind("Container(", 0, s)
if container_start == -1:
    print("❌ Fant ikke start på Container før introteksten.")
    print("Kjør dette og send resultatet:")
    print("  sed -n '120,220p' lib/pages/travel_page.dart")
    raise SystemExit(1)

depth = 0
i = container_start
end_pos = -1
while i < len(text):
    if text.startswith("Container(", i):
        depth += 1
        i += len("Container(")
        continue
    ch = text[i]
    if ch == "(":
        depth += 1
    elif ch == ")":
        depth -= 1
        if depth <= 0:
            end_pos = i + 1
            break
    i += 1

if end_pos == -1:
    print("❌ Fant ikke slutten på intro-containeren.")
    print("Kjør dette og send resultatet:")
    print("  sed -n '120,220p' lib/pages/travel_page.dart")
    raise SystemExit(1)

# ta med evt etterfølgende komma og linjeskift
while end_pos < len(text) and text[end_pos] in ", \t\r\n":
    end_pos += 1

text = text[:container_start] + text[end_pos:]

if text == orig:
    print("❌ Ingen endring gjort.")
    raise SystemExit(1)

path.write_text(text)
print("✅ Fjernet introblokk via fallback.")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
