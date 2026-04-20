#!/usr/bin/env bash
set -euo pipefail

echo "==> 791_find_and_fix_active_hero_overlay"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_791")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# Finn aktiv hero rundt teksten som faktisk vises
anchor = "Planlegg reisen smartere"
idx = text.find(anchor)
if idx == -1:
    print("❌ Fant ikke hero-teksten 'Planlegg reisen smartere'")
    print("Kjør dette og send resultatet:")
    print("  sed -n '130,260p' lib/pages/travel_page.dart")
    raise SystemExit(1)

start = max(0, idx - 2200)
end = min(len(text), idx + 2200)
chunk = text[start:end]

print("---- HERO UTSNITT START ----")
print(chunk[:2500])
print("---- HERO UTSNITT SLUTT ----")

new_chunk = chunk

# Vanlige mønstre vi vil lette
replacements = [
    (r"withOpacity\(\s*0\.6\s*\)", "withValues(alpha: 0.14)"),
    (r"withOpacity\(\s*0\.55\s*\)", "withValues(alpha: 0.14)"),
    (r"withOpacity\(\s*0\.5\s*\)", "withValues(alpha: 0.13)"),
    (r"withOpacity\(\s*0\.45\s*\)", "withValues(alpha: 0.12)"),
    (r"withOpacity\(\s*0\.4\s*\)", "withValues(alpha: 0.11)"),
    (r"withOpacity\(\s*0\.35\s*\)", "withValues(alpha: 0.10)"),
    (r"withOpacity\(\s*0\.3\s*\)", "withValues(alpha: 0.09)"),
    (r"withOpacity\(\s*0\.25\s*\)", "withValues(alpha: 0.08)"),
    (r"withOpacity\(\s*0\.2\s*\)", "withValues(alpha: 0.07)"),
    (r"withValues\(alpha:\s*0\.6\s*\)", "withValues(alpha: 0.14)"),
    (r"withValues\(alpha:\s*0\.55\s*\)", "withValues(alpha: 0.14)"),
    (r"withValues\(alpha:\s*0\.5\s*\)", "withValues(alpha: 0.13)"),
    (r"withValues\(alpha:\s*0\.45\s*\)", "withValues(alpha: 0.12)"),
    (r"withValues\(alpha:\s*0\.4\s*\)", "withValues(alpha: 0.11)"),
    (r"withValues\(alpha:\s*0\.35\s*\)", "withValues(alpha: 0.10)"),
    (r"withValues\(alpha:\s*0\.3\s*\)", "withValues(alpha: 0.09)"),
]

for pattern, repl in replacements:
    new_chunk = re.sub(pattern, repl, new_chunk)

# Hvis heroen bruker mørk toning via svarte farger, lette dem eksplisitt
new_chunk = new_chunk.replace("Color(0xCC000000)", "Color(0x24000000)")
new_chunk = new_chunk.replace("Color(0xAA000000)", "Color(0x1F000000)")
new_chunk = new_chunk.replace("Color(0x99000000)", "Color(0x1A000000)")
new_chunk = new_chunk.replace("Color(0x88000000)", "Color(0x16000000)")

if new_chunk == chunk:
    print("❌ Fant ingen overlay-verdier å endre i aktiv hero.")
    print("Kjør dette og send resultatet:")
    print("  sed -n '130,260p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text[:start] + new_chunk + text[end:]
path.write_text(text)
print("✅ Aktiv hero-overlay lettet")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
