#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/eb_shopping_page.dart"

echo "==> patch_758_fix_premium_header_paywall_callback"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_758_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()
original = text
report = []

# 1) Add callback field to _PremiumHeader if missing
if "final VoidCallback? onOpenPremiumPaywall;" not in text:
    pattern = r"(class\s+_PremiumHeader\s+extends\s+StatelessWidget\s*\{\s*)"
    repl = r"\1\n  final VoidCallback? onOpenPremiumPaywall;\n"
    text, n = re.subn(pattern, repl, text, count=1, flags=re.DOTALL)
    if n:
        report.append("la til field: onOpenPremiumPaywall")
    else:
        report.append("ADVARSEL: fant ikke _PremiumHeader class for field")

# 2) Update constructor to accept callback if missing
if "this.onOpenPremiumPaywall" not in text:
    # common const constructor
    patterns = [
        (
            r"(const\s+_PremiumHeader\s*\(\s*\{\s*super\.key,\s*)\}\s*\);",
            r"\1this.onOpenPremiumPaywall,\n  }\);"
        ),
        (
            r"(const\s+_PremiumHeader\s*\(\s*\{\s*)super\.key,\s*(.*?)\}\s*\);",
            r"\1super.key,\n    this.onOpenPremiumPaywall,\n    \2}\);"
        ),
    ]
    matched = False
    for p, r in patterns:
        text2, n = re.subn(p, r, text, count=1, flags=re.DOTALL)
        if n:
            text = text2
            matched = True
            report.append("oppdaterte _PremiumHeader constructor")
            break
    if not matched:
        report.append("ADVARSEL: fant ikke constructor-mønster for _PremiumHeader")

# 3) Replace _openPremiumPaywall references inside _PremiumHeader with callback
text, n = re.subn(r"\b_openPremiumPaywall\b", "onOpenPremiumPaywall", text)
if n:
    report.append(f"erstattet _openPremiumPaywall inne i filen ({n} treff)")
else:
    report.append("ingen _openPremiumPaywall-treff erstattet")

# 4) Ensure _PremiumHeader instantiation passes callback
# only add where _PremiumHeader( is used and callback missing
def add_callback(match):
    inner = match.group(1)
    if "onOpenPremiumPaywall:" in inner:
        return match.group(0)
    return "_PremiumHeader(\n" + inner + "  onOpenPremiumPaywall: _openPremiumPaywall,\n)"

text, n = re.subn(r"_PremiumHeader\(\n(.*?)\)", add_callback, text, count=1, flags=re.DOTALL)
if n:
    report.append("sendte callback inn i _PremiumHeader(...)")
else:
    report.append("ADVARSEL: fant ikke _PremiumHeader(...) for callback-wiring")

# 5) Clean a common bad onPressed shape if it became onPressed: () => onOpenPremiumPaywall()
text, n = re.subn(r"onPressed:\s*\(\)\s*=>\s*onOpenPremiumPaywall\(\)", "onPressed: onOpenPremiumPaywall", text)
if n:
    report.append("normaliserte onPressed: onOpenPremiumPaywall")

# 6) Also normalize onTap if any
text, n = re.subn(r"onTap:\s*\(\)\s*=>\s*onOpenPremiumPaywall\(\)", "onTap: onOpenPremiumPaywall", text)
if n:
    report.append("normaliserte onTap: onOpenPremiumPaywall")

path.write_text(text)
Path("lib/paywall/_patch_758_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_758_report.txt || true

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) hvis fortsatt feil, kjør:"
echo "   sed -n '1120,1205p' lib/pages/eb_shopping_page.dart"
