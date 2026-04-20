#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/eb_shopping_page.dart"

echo "==> patch_760_fix_premium_header_constructor_exact"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_760_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()

old = """class _PremiumHeader extends StatelessWidget {
  
  final VoidCallback? onOpenPremiumPaywall;
const _PremiumHeader();
"""

new = """class _PremiumHeader extends StatelessWidget {
  final VoidCallback? onOpenPremiumPaywall;

  const _PremiumHeader({
    this.onOpenPremiumPaywall,
  });
"""

if old not in text:
    # Litt mer tolerant fallback
    import re
    pattern = r"class _PremiumHeader extends StatelessWidget \{\s*final VoidCallback\? onOpenPremiumPaywall;\s*const _PremiumHeader\(\);\s*"
    repl = """class _PremiumHeader extends StatelessWidget {
  final VoidCallback? onOpenPremiumPaywall;

  const _PremiumHeader({
    this.onOpenPremiumPaywall,
  });

"""
    text2, n = re.subn(pattern, repl, text, count=1, flags=re.DOTALL)
    if n == 0:
        raise SystemExit("❌ Fant ikke _PremiumHeader-blokken å patche")
    text = text2
else:
    text = text.replace(old, new, 1)

path.write_text(text)
print("✅ Fikset _PremiumHeader-constructor")
PY

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) hvis grønt nok: flutter run"
