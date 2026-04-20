#!/usr/bin/env bash
set -euo pipefail

echo "==> 818b_fix_broken_column_in_premium_page"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_818b")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1) Fjern ubrukt import hvis checkout ikke lenger brukes
text = text.replace("import 'checkout_page.dart';\n", "")

broken = """                      child: Column(
            const SizedBox(height: 12),
            Text(
              'Dette er et auto-fornybart abonnement. Betaling skjer via din Apple-ID. '
              'Abonnementet fornyes automatisk med mindre det kanselleres minst 24 timer før slutten av perioden.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
"""

fixed = """                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Dette er et auto-fornybart abonnement. Betaling skjer via din Apple-ID. '
                            'Abonnementet fornyes automatisk med mindre det kanselleres minst 24 timer før slutten av perioden.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
"""

if broken not in text:
    print("❌ Fant ikke eksakt ødelagt Column-blokk")
    print("Kjør og send:")
    print("  sed -n '170,220p' lib/pages/premium_page.dart")
    raise SystemExit(1)

text = text.replace(broken, fixed, 1)

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 818b ferdig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
