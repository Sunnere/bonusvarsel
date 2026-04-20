#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_681_set_free_blue_premium_green_keep_elite"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text
changed = False

# 1) Sørg for tydelige bools i _PlanCard
old = """  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isElite = title == 'Elite';"""

new = """  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isElite = title == 'Elite';
    final isPremium = title == 'Premium';
    final isFree = title == 'Gratis';"""

if old in text:
    text = text.replace(old, new, 1)
    changed = True

# 2) Border colors: Gratis blå, Premium grønn, Elite gull
pattern = re.compile(
    r"""final\s+borderColor\s*=\s*selected\s*
        \?\s*\(isElite
        .*?
        :\s*cs\.onSurface\.withValues\(alpha:\s*0\.36\)\s*;""",
    re.DOTALL | re.VERBOSE,
)

replacement = """final borderColor = selected
        ? (isElite
            ? const Color(0xFFD4AF37)
            : isPremium
                ? const Color(0xFF22C55E)
                : isFree
                    ? const Color(0xFF60A5FA)
                    : accent.withValues(alpha: 0.85))
        : (emphasis
            ? (isElite
                ? const Color(0xFFD4AF37).withValues(alpha: 0.58)
                : isPremium
                    ? const Color(0xFF22C55E).withValues(alpha: 0.48)
                    : isFree
                        ? const Color(0xFF60A5FA).withValues(alpha: 0.42)
                        : accent.withValues(alpha: 0.45))
            : cs.onSurface.withValues(alpha: 0.36));"""

text2, count = pattern.subn(replacement, text, count=1)
if count:
    text = text2
    changed = True

# 3) Bakgrunn: Gratis blå, Premium grønn, Elite beholdes
pattern = re.compile(
    r"""final\s+bg\s*=\s*isElite
        \s*\?\s*\(selected
        .*?
        :\s*\(title\s*==\s*'Premium'
            \s*\?\s*const\s+Color\(0xFFF6FAFF\)
            \s*:\s*cs\.surface\.withValues\(alpha:\s*emphasis\s*\?\s*0\.92\s*:\s*0\.80\)\)\s*;""",
    re.DOTALL | re.VERBOSE,
)

replacement = """final bg = isElite
        ? (selected
            ? const Color(0xFF140F2A)
            : const Color(0xFF101826))
        : isPremium
            ? (selected
                ? const Color(0xFF0F3D2E)
                : const Color(0xFF123A2C))
            : isFree
                ? (selected
                    ? const Color(0xFF173B63)
                    : const Color(0xFF102A43))
                : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80);"""

text2, count = pattern.subn(replacement, text, count=1)
if count:
    text = text2
    changed = True

# 4) Tittel: hvit på Gratis/Premium, gull på Elite
old = """                          color: isElite
                              ? const Color(0xFFFFE08A)
                              : (title == 'Premium'
                                  ? const Color(0xFF0F172A)
                                  : null),"""

new = """                          color: isElite
                              ? const Color(0xFFFFE08A)
                              : (isPremium || isFree
                                  ? Colors.white
                                  : null),"""

if old in text:
    text = text.replace(old, new, 1)
    changed = True

# 5) Badge-bakgrunn/border: Gratis blå, Premium grønn, Elite gull
old = """                      color: isElite
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.24)
                          : (emphasis ? accent : cs.onSurface)
                              .withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isElite
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.78)
                            : (emphasis ? accent : cs.onSurface)
                                .withValues(alpha: 0.36),
                      ),"""

new = """                      color: isElite
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.24)
                          : isPremium
                              ? const Color(0xFF22C55E).withValues(alpha: 0.18)
                              : isFree
                                  ? const Color(0xFF60A5FA).withValues(alpha: 0.18)
                                  : (emphasis ? accent : cs.onSurface)
                                      .withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isElite
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.78)
                            : isPremium
                                ? const Color(0xFF22C55E).withValues(alpha: 0.58)
                                : isFree
                                    ? const Color(0xFF60A5FA).withValues(alpha: 0.54)
                                    : (emphasis ? accent : cs.onSurface)
                                        .withValues(alpha: 0.36),
                      ),"""

if old in text:
    text = text.replace(old, new, 1)
    changed = True

# 6) Gratis CTA blå
free_pat = re.compile(
    r"""(_PlanCard\(
\s*title:\s*'Gratis',
.*?
\s*ctaLabel:\s*'Gratis',
)(.*?)(\s*onCta:\s*\(\)\s*=>\s*onCheckout\('Gratis'\),
\s*\),)""",
    re.DOTALL | re.VERBOSE,
)

m = free_pat.search(text)
if m:
    before, middle, after = m.group(1), m.group(2), m.group(3)
    middle = re.sub(r"\s*ctaColor:\s*const\s+Color\([^)]+\),\n", "\n", middle)
    injected = """          ctaColor: const Color(0xFF60A5FA),
"""
    text = text[:m.start()] + before + injected + after + text[m.end():]
    changed = True

# 7) Premium CTA grønn
premium_pat = re.compile(
    r"""(_PlanCard\(
\s*title:\s*'Premium',
.*?
\s*ctaLabel:\s*'Premium',
)(.*?)(\s*onCta:\s*\(\)\s*=>\s*onCheckout\('Premium'\),
\s*\),)""",
    re.DOTALL | re.VERBOSE,
)

m = premium_pat.search(text)
if m:
    before, middle, after = m.group(1), m.group(2), m.group(3)
    middle = re.sub(r"\s*ctaColor:\s*const\s+Color\([^)]+\),\n", "\n", middle)
    middle = re.sub(r"\s*note:\s*'[^']*',\n", "\n", middle)
    injected = """          ctaColor: const Color(0xFF22C55E),
          note: 'Typisk ekstra: +2k–8k poeng/år',
"""
    text = text[:m.start()] + before + injected + after + text[m.end():]
    changed = True

if not changed:
    print("❌ Fant ikke forventede mønstre. Ingen endring gjort.")
    sys.exit(1)

path.write_text(text)
print("✅ Satte Gratis blå, Premium grønn og lot Elite være luksus")
PY

echo
echo "==> Verifiser nøkkelverdier"
grep -n "isPremium =\|isFree =\|102A43\|123A2C\|22C55E\|60A5FA\|title: 'Gratis'\|title: 'Premium'\|title: 'Elite'" "$FILE" || true

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
