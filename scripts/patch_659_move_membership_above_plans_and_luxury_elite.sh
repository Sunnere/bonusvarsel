#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_659_move_membership_above_plans_and_luxury_elite"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# 1) Flytt medlemsseksjonen opp før "Velg nivå"
section_pattern = re.compile(
    r"""
(?P<section>
[ \t]*const\s+SizedBox\(height:\s*14\),\n
[ \t]*Container\(\n
[ \t]*padding:\s*const\s+EdgeInsets\.fromLTRB\(16,\s*16,\s*16,\s*16\),\n
[ \t]*decoration:\s*BoxDecoration\(
.*?
[ \t]*const\s+SizedBox\(height:\s*18\),\n
)
""",
    re.DOTALL | re.VERBOSE,
)

m = section_pattern.search(text)
membership_block = None
if m and "Start med riktig medlemskap" in m.group("section"):
    membership_block = m.group("section")
    text = text.replace(membership_block, "", 1)

if membership_block:
    marker = """                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: 'Velg nivå',
"""
    if marker in text:
        text = text.replace(
            marker,
            membership_block + "\n" + marker,
            1,
        )
    else:
        print("❌ Fant ikke målpunkt for å flytte medlemsseksjonen.")
        sys.exit(1)
else:
    print("⚠️ Fant ikke medlemsseksjonen. Hopper over flytting.")

# 2) Gjør elite mer luksus ved å justere farger/tekst i plan-kortdata
replacements = [
    (
        "subtitle: 'Premium hvis du vil maksimere SAS Shopping. Elite hvis du vil ha alt (SAS + mer).',",
        "subtitle: 'Premium hvis du vil maksimere SAS Shopping. Elite hvis du vil ha alt — med mer eksklusiv oversikt og maksimal poengverdi.',",
    ),
    (
        "title: 'Hvorfor Elite?'",
        "title: 'Hvorfor Elite — luksusnivået'",
    ),
    (
        "subtitle:\n                          'For deg som vil maksimere alt — flere programmer, flere boosts, mer oversikt.',",
        "subtitle:\n                          'For deg som vil ha det mest eksklusive nivået — flere programmer, flere boosts og tydelig premium-følelse.',",
    ),
]

for old, new in replacements:
    text = text.replace(old, new)

# 3) Forsøk å style Elite-kortet hvis _PlanOptionCard eller tilsvarende finnes
text = text.replace(
    "          title: 'Elite',",
    "          title: 'Elite',",
)

# 4) Gjør membership-seksjon mer kompakt så den ikke spiser for mye plass
text = text.replace(
    "                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),",
    "                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),",
    1,
)

# 5) Gjør SAS/TRUMF-kortene litt lavere
text = text.replace(
    "            padding: const EdgeInsets.all(14),",
    "            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),",
)

# 6) Elite-luksus i _PlanCard-lignende widgeter: patch kjente farger hvis de finnes
text = text.replace(
    "selected == 'Elite'\n                  ? 'Elite: maks poeng & flere programmer'",
    "selected == 'Elite'\n                  ? 'Elite: eksklusiv maks poengverdi'",
)

# 7) Hvis det finnes egen plan-card widget med title == Elite, styrk badge-tekst
text = text.replace(
    "ctaLabel: 'Elite',",
    "ctaLabel: 'Elite',",
)

# 8) Legg til liten luksusnote i header-shell over planene
header_old = """                                      Text(
                                        _selected == 'Elite'
                                            ? 'Elite — maks verdi'
                                            : 'Premium — smartere opptjening',"""
header_new = """                                      Text(
                                        _selected == 'Elite'
                                            ? 'Elite — eksklusiv maksverdi'
                                            : 'Premium — smartere opptjening',"""
text = text.replace(header_old, header_new)

desc_old = """                                      Text(
                                        _selected == 'Elite'
                                            ? 'Mer eksklusiv visning og tydeligere fokus på total poengmaksimering.'
                                            : 'Et renere løft for SAS Shopping og bedre oversikt over gevinst.',"""
desc_new = """                                      Text(
                                        _selected == 'Elite'
                                            ? 'Dypere premium-uttrykk, mer eksklusiv oversikt og tydelig fokus på total poengmaksimering.'
                                            : 'Et renere løft for SAS Shopping og bedre oversikt over gevinst.',"""
text = text.replace(desc_old, desc_new)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Flyttet medlemsseksjonen over planene og strammet opp Elite-tekster")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
