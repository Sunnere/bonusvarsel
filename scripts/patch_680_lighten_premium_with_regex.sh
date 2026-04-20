#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_680_lighten_premium_with_regex"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

echo
echo "==> Før patch: relevante linjer"
grep -n "title: 'Premium'\|final borderColor =\|final bg =\|ctaColor:" "$FILE" || true

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text
changed = False

# 1) Lysne Premium-bakgrunn i _PlanCard
bg_pat = re.compile(
    r"""final\s+bg\s*=\s*isElite\s*
        \?\s*\(selected
        .*?
        :\s*cs\.surface\.withValues\(alpha:\s*emphasis\s*\?\s*0\.92\s*:\s*0\.80\)\s*;""",
    re.DOTALL | re.VERBOSE,
)

bg_repl = """final bg = isElite
        ? (selected
            ? const Color(0xFF140F2A)
            : const Color(0xFF101826))
        : (title == 'Premium'
            ? const Color(0xFFF6FAFF)
            : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80));"""

text2, count = bg_pat.subn(bg_repl, text, count=1)
if count:
    text = text2
    changed = True

# 2) Gi Premium mykere, lys blå kant i _PlanCard
border_pat = re.compile(
    r"""final\s+borderColor\s*=\s*selected\s*
        \?\s*\(isElite
        .*?
        :\s*cs\.onSurface\.withValues\(alpha:\s*0\.36\)\s*;""",
    re.DOTALL | re.VERBOSE,
)

border_repl = """final borderColor = selected
        ? (isElite
            ? const Color(0xFFD4AF37)
            : accent.withValues(alpha: 0.85))
        : (emphasis
            ? (isElite
                ? const Color(0xFFD4AF37).withValues(alpha: 0.58)
                : (title == 'Premium'
                    ? const Color(0xFF93C5FD)
                    : accent.withValues(alpha: 0.45)))
            : cs.onSurface.withValues(alpha: 0.36));"""

text2, count = border_pat.subn(border_repl, text, count=1)
if count:
    text = text2
    changed = True

# 3) Gjør Premium CTA lysere blå i selve Premium-kortet
premium_block_pat = re.compile(
    r"""(_PlanCard\(
\s*title:\s*'Premium',
.*?
\s*ctaLabel:\s*'Premium',
)(.*?)(\s*onCta:\s*\(\)\s*=>\s*onCheckout\('Premium'\),
\s*\),)""",
    re.DOTALL | re.VERBOSE,
)

m = premium_block_pat.search(text)
if m:
    before, middle, after = m.group(1), m.group(2), m.group(3)
    # fjern eksisterende ctaColor/note fra middle hvis de finnes, og sett inn våre verdier
    middle = re.sub(r"\s*ctaColor:\s*const\s+Color\([^)]+\),\n", "\n", middle)
    middle = re.sub(r"\s*note:\s*'[^']*',\n", "\n", middle)
    injected = """          ctaColor: const Color(0xFF60A5FA),
          note: 'Typisk ekstra: +2k–8k poeng/år',
"""
    new_block = before + injected + after
    text = text[:m.start()] + new_block + text[m.end():]
    changed = True

if not changed:
    print("❌ Fant ikke de riktige blokkene. Ingen endring gjort.")
    sys.exit(1)

path.write_text(text)
print("✅ Premium lysnet med robust regex-patch")
PY

echo
echo "==> Etter patch: relevante linjer"
grep -n "title: 'Premium'\|F6FAFF\|93C5FD\|60A5FA\|final borderColor =\|final bg =" "$FILE" || true

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
