#!/usr/bin/env bash
set -euo pipefail

echo "==> 730_fix_travel_hero_image_fallback"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_730")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()

# Replace Image.asset with fallback-safe version
text = text.replace(
    "Image.asset(",
    """Image.asset(
                """,
)

# Add errorBuilder fallback (only if not already added)
if "errorBuilder:" not in text:
    text = text.replace(
        "fit: BoxFit.cover,",
        """fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0F3D5E),
                          Color(0xFF1B6B73),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.flight_takeoff,
                          color: Colors.white, size: 42),
                    ),
                  );
                },""",
    )

path.write_text(text)
print("Patched hero fallback")
PY

echo
echo "✅ 730 ferdig"
echo
echo "Neste steg:"
echo "Legg faktisk bilde i:"
echo "assets/images/travel_hero.jpg"
echo
echo "Kjør:"
echo "flutter pub get"
echo "flutter run"
