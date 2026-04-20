#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/eb_shopping_page.dart"

echo "==> patch_759_fix_premium_header_constructor_init"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_759_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()
report = []

# Ensure field exists
if "final VoidCallback? onOpenPremiumPaywall;" not in text:
    raise SystemExit("❌ Field 'onOpenPremiumPaywall' finnes ikke. Kjør patch_758 først eller sjekk fila.")

# Fix constructor by inserting this.onOpenPremiumPaywall,
# into _PremiumHeader({ ... })
patterns = [
    (
        r"(const\s+_PremiumHeader\s*\(\s*\{\s*super\.key,\s*)(\}\s*\);)",
        r"\1this.onOpenPremiumPaywall,\n  \2"
    ),
    (
        r"(const\s+_PremiumHeader\s*\(\s*\{\s*)([^}]*)\}\s*\);",
        None
    ),
]

changed = False

# Specific simple case first
new_text, n = re.subn(patterns[0][0], patterns[0][1], text, count=1, flags=re.DOTALL)
if n:
    text = new_text
    changed = True
    report.append("la til this.onOpenPremiumPaywall i _PremiumHeader-constructor")

if not changed:
    # More general constructor patch
    m = re.search(patterns[1][0], text, flags=re.DOTALL)
    if m:
        full = m.group(0)
        body = m.group(2)
        if "this.onOpenPremiumPaywall" not in body:
            body = body.rstrip()
            if body and not body.endswith(","):
                body += ","
            replacement = f"const _PremiumHeader({{{body}\n    this.onOpenPremiumPaywall,\n  }});"
            text = text.replace(full, replacement, 1)
            changed = True
            report.append("oppdaterte eksisterende _PremiumHeader-constructor med this.onOpenPremiumPaywall")

if not changed:
    report.append("ingen constructor-endring gjort")

path.write_text(text)
Path("lib/paywall/_patch_759_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_759_report.txt || true

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) hvis det fortsatt feiler, kjør:"
echo "   sed -n '1100,1135p' lib/pages/eb_shopping_page.dart"
