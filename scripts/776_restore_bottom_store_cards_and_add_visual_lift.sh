#!/usr/bin/env bash
set -euo pipefail

echo "==> 776_restore_bottom_store_cards_and_add_visual_lift"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_776")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

helpers = r"""
  Widget _travelStoreTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> tags,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF8FCFD),
            Color(0xFFF0FAFB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD3ECEE),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF163A70),
                  Color(0xFF1E8C98),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF163038),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4D636B),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F6F7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFCBE6E8),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF27535B),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

"""

anchor = "  @override\n  Widget build(BuildContext context) {"
if helpers not in text:
    if anchor not in text:
        print("❌ Fant ikke build()-anker")
        raise SystemExit(1)
    text = text.replace(anchor, helpers + "\n" + anchor, 1)

pattern = re.compile(
    r"""
                        Text\(
                          'Butikktyper\ som\ passer\ best',
                          style:\ _sectionTitleStyle\(context\),
                        \),
                        const\ SizedBox\(height:\ 12\),
                        if\s+\(storeSuggestions\.any\(\(s\)\ =>\ s\.title\.trim\(\)\.isNotEmpty\)\)
                        \s+for\s+\(final\s+s\s+in\s+storeSuggestions\.take\(5\)\)\s+\.\.\.\[
.*?
                        Text\(
                          'Live-blokken\ viser\ anbefalte\ butikker\ basert\ på\ planen\ din\.',
                          style:\ Theme\.of\(context\)\.textTheme\.bodySmall\?\.copyWith\(
.*?
                        \),
""",
    re.DOTALL | re.VERBOSE,
)

replacement = """                        Text(
                          'Butikktyper som passer best',
                          style: _sectionTitleStyle(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kuraterte butikktyper basert på reisemål, familiestørrelse og behov før avreise.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5B7077),
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 14),
                        _travelStoreTypeCard(
                          context: context,
                          icon: Icons.luggage_rounded,
                          title: 'Bagasje og kofferter',
                          subtitle: 'For familier som trenger mer plass, bedre organisering og enklere pakking.',
                          tags: const ['Bagasje', 'Familie', 'Organisering'],
                        ),
                        _travelStoreTypeCard(
                          context: context,
                          icon: Icons.health_and_safety_outlined,
                          title: 'Apotek og helsebutikk',
                          subtitle: 'Praktisk for solkrem, hygiene, reiseapotek og ting som ofte glemmes før tur.',
                          tags: const ['Apotek', 'Helse', 'Hudpleie'],
                        ),
                        _travelStoreTypeCard(
                          context: context,
                          icon: Icons.downhill_skiing_outlined,
                          title: 'Sportsbutikk / friluft',
                          subtitle: 'God match for vinterutstyr, strandutstyr og aktiv ferie med barn.',
                          tags: const ['Sport', 'Friluft', 'Aktiv ferie'],
                        ),
                        _travelStoreTypeCard(
                          context: context,
                          icon: Icons.checkroom_outlined,
                          title: 'Klesbutikk / skobutikk',
                          subtitle: 'Relevante kjøp for badetøy, lette sommerklær, gåsko og familieinnkjøp.',
                          tags: const ['Klær', 'Sko', 'Sommer'],
                        ),
                        _travelStoreTypeCard(
                          context: context,
                          icon: Icons.devices_other_outlined,
                          title: 'Elektronikkbutikk',
                          subtitle: 'Ladere, adaptere, powerbank og småting som gjør reisen enklere.',
                          tags: const ['Elektronikk', 'Lading', 'Reisetilbehør'],
                        ),
                        Text(
                          'Denne blokken skal føles som et levende shoppingkart for reisen, ikke en tom liste.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF61757D),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
"""

new_text, count = pattern.subn(replacement, text, count=1)
if count == 0:
    print("❌ Fant ikke butikkblokka som skulle oppgraderes.")
    print("Kjør og send:")
    print("  sed -n '1248,1315p' lib/pages/travel_page.dart")
    raise SystemExit(1)

# Liten visuell boost på seksjonskortet som holder butikkene
new_text = new_text.replace(
"""              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),""",
"""              Card(
                color: const Color(0xFFFFFEFC),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Color(0xFFE5EFEF), width: 1.1),
                ),""",
1)

if new_text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(new_text)
print(f"✅ Oppgraderte butikkseksjonen i: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
