#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/main.dart"

echo "==> patch_764_add_named_premium_route_in_main"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_764_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/main.dart")
text = path.read_text()
original = text
report = []

# 1) Ensure premium_page import exists
premium_import = "import 'package:bonusvarsel/pages/premium_page.dart';"
if premium_import not in text:
    imports = list(re.finditer(r"^import .+?;\n", text, flags=re.MULTILINE))
    if imports:
        last = imports[-1]
        text = text[:last.end()] + premium_import + "\n" + text[last.end():]
    else:
        text = premium_import + "\n" + text
    report.append("la til import for premium_page.dart")
else:
    report.append("premium_page.dart-import finnes allerede")

# 2) If '/premium' already exists, do nothing more
if re.search(r"['\"]/premium['\"]\s*:", text):
    report.append("'/premium' route finnes allerede")
    path.write_text(text)
    Path("lib/paywall/_patch_764_report.txt").write_text("\n".join(report) + "\n")
    print("\n".join(report))
    raise SystemExit(0)

# 3) If routes: {} exists, inject entry
routes_match = re.search(r"routes\s*:\s*\{", text)
if routes_match:
    insert_at = routes_match.end()
    entry = "\n        '/premium': (_) => const PremiumPage(),"
    text = text[:insert_at] + entry + text[insert_at:]
    report.append("la til '/premium' i eksisterende routes-map")
else:
    # 4) Otherwise inject routes: into MaterialApp(
    material_app_match = re.search(r"MaterialApp\s*\(", text)
    if not material_app_match:
        Path("lib/paywall/_patch_764_report.txt").write_text(
            "ADVARSEL: fant ikke MaterialApp( i lib/main.dart\n"
        )
        print("ADVARSEL: fant ikke MaterialApp( i lib/main.dart")
        raise SystemExit(1)

    insert_at = material_app_match.end()
    snippet = """
      routes: {
        '/premium': (_) => const PremiumPage(),
      },
"""
    text = text[:insert_at] + snippet + text[insert_at:]
    report.append("la til ny routes-map med '/premium' i MaterialApp")

path.write_text(text)
Path("lib/paywall/_patch_764_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_764_report.txt || true

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) test paywall -> Fortsett til betaling"
echo "3) premium-siden skal nå åpnes via named route '/premium'"
