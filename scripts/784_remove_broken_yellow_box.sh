#!/usr/bin/env bash
set -euo pipefail

echo "==> 784_remove_broken_yellow_box"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_784")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# Fjern gul container (typisk gradient/gul bakgrunn)
text = re.sub(
    r"Container\(\s*margin: const EdgeInsets\.only\(bottom: 16\),\s*padding: const EdgeInsets\.all\(16\),\s*decoration: BoxDecoration\(\s*gradient:.*?borderRadius: BorderRadius\.circular\(.*?\),\s*\),\s*child: .*?\),",
    "",
    text,
    flags=re.DOTALL
)

if text == orig:
    print("⚠️ Fant ikke eksakt match – prøver fallback")

    # fallback: fjern container med gul bakgrunn
    text = re.sub(
        r"Container\([\s\S]*?Color\(0xFFFF.*?\)[\s\S]*?\),",
        "",
        text
    )

if text == orig:
    print("❌ Ingen endring – må justere regex manuelt")
    raise SystemExit(1)

path.write_text(text)
print("✅ Fjernet ødelagt gul blokk")
PY

echo
echo "Kjør:"
echo "  flutter analyze"
echo "  flutter run -d macos"
