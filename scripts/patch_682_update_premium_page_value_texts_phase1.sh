#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_682_update_premium_page_value_texts_phase1"
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

replacements = [
    (
        "Du mister ekstra poeng hver gang du handler uten Premium/Elite.",
        "Typisk bruk kan gi ca. 1 500–4 000 ekstra poeng per måned med riktige valg.",
    ),
    (
        "Gjør det lett å samle nok poeng til billigere (eller gratis) reiser.",
        "Aktiv bruk kan gi opptil 8 000+ poeng per måned og gjøre reiser merkbart billigere.",
    ),
    (
        "Premium hvis du vil maksimere SAS Shopping. Elite hvis du vil ha alt — med mer eksklusiv oversikt og maksimal poengverdi.",
        "Premium for deg som vil maksimere SAS Shopping. Elite for deg som vil ha flere programmer og mest mulig poengverdi.",
    ),
    (
        "Et renere løft for SAS Shopping og bedre oversikt over gevinst.",
        "Typisk: +1 500–4 000 ekstra poeng per måned ved normal bruk.",
    ),
    (
        "Dypere premium-uttrykk, mer eksklusiv oversikt og tydelig fokus på total poengmaksimering.",
        "Opptil 8 000+ poeng per måned ved aktiv bruk og flere programmer.",
    ),
    (
        "Typisk ekstra: +2k–8k poeng/år",
        "Typisk: +1 500–4 000 poeng/mnd",
    ),
    (
        "Luksusnivå: maks poengverdi + flere programmer",
        "Opptil 8 000+ poeng/mnd",
    ),
]

for old, new in replacements:
    if old in text:
        text = text.replace(old, new)
        changed = True

# Premium-pris i CTA-label / note-seksjoner hvis slike finnes
patterns = [
    (
        r"49\s*kr/mnd",
        "49 kr/mnd",
    ),
    (
        r"89\s*kr/mnd",
        "89 kr/mnd",
    ),
]

for pat, repl in patterns:
    new_text, count = re.subn(pat, repl, text)
    if count:
        text = new_text
        changed = True

# Legg inn prislinjer i Premium-kortet hvis note finnes men pris ikke er tydelig
premium_block_pat = re.compile(
    r"""(_PlanCard\(
\s*title:\s*'Premium',
.*?
\s*ctaLabel:\s*'Premium',
.*?
\s*note:\s*')([^']*)(',
.*?\s*onCta:\s*\(\)\s*=>\s*onCheckout\('Premium'\),
\s*\),)""",
    re.DOTALL | re.VERBOSE,
)

m = premium_block_pat.search(text)
if m and "49 kr/mnd" not in m.group(2):
    text = text[:m.start()] + (
        m.group(1) + "49 kr/mnd · Typisk: +1 500–4 000 poeng/mnd" + m.group(3) + text[m.end(3):m.end()]
    ) + text[m.end():]
    changed = True

elite_block_pat = re.compile(
    r"""(_PlanCard\(
\s*title:\s*'Elite',
.*?
\s*ctaLabel:\s*'Elite',
.*?
\s*note:\s*')([^']*)(',
.*?\s*onCta:\s*\(\)\s*=>\s*onCheckout\('Elite'\),
\s*\),)""",
    re.DOTALL | re.VERBOSE,
)

m = elite_block_pat.search(text)
if m and "89 kr/mnd" not in m.group(2):
    text = text[:m.start()] + (
        m.group(1) + "89 kr/mnd · Opptil 8 000+ poeng/mnd" + m.group(3) + text[m.end(3):m.end()]
    ) + text[m.end():]
    changed = True

if not changed:
    print("⚠️ Fant ingen kjente tekstmønstre å oppdatere.")
    sys.exit(2)

path.write_text(text)
print("✅ Oppdaterte PremiumPage-tekster for fase 1-prising og verdi")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "==> Verifiser oppdaterte tekster"
grep -n "1 500–4 000\|8 000+\|49 kr/mnd\|89 kr/mnd" "$FILE" || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
