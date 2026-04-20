#!/usr/bin/env bash
set -euo pipefail

echo "==> 744_upgrade_travel_store_section_to_visual_cards"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_744")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Utvid _StoreSuggestion med visual fields
text = text.replace(
"""class _StoreSuggestion {
  final String title;
  final String why;

  const _StoreSuggestion({
    required this.title,
    required this.why,
  });
}""",
"""class _StoreSuggestion {
  final String title;
  final String why;
  final String imageAsset;
  final String hint;
  final String pointsLabel;

  const _StoreSuggestion({
    required this.title,
    required this.why,
    required this.imageAsset,
    required this.hint,
    required this.pointsLabel,
  });
}"""
)

# 2) Bytt _buildStoreSuggestions til rikere butikkdata
pattern = re.compile(
    r"  List<_StoreSuggestion> _buildStoreSuggestions\(List<_PackingNeed> needs\) \{.*?^  int _suggestedTargetPoints\(\) \{",
    re.DOTALL | re.MULTILINE
)

replacement = """  List<_StoreSuggestion> _buildStoreSuggestions(List<_PackingNeed> needs) {
    final categories = <String>{};
    final hints = <String>{};

    for (final need in needs) {
      categories.add(need.category);
      hints.add(need.storeHint);
    }

    final results = <_StoreSuggestion>[];

    if (categories.contains('Bagasje')) {
      results.add(
        const _StoreSuggestion(
          title: 'Bagasje og kofferter',
          why: 'Høy relevans for familie på 4, flere kolli og bedre organisering før avreise.',
          imageAsset: 'assets/images/travel/need_luggage.jpg',
          hint: 'Koffert, cabin bag, reiseorganisering',
          pointsLabel: 'Typisk høy verdi',
        ),
      );
    }

    if (categories.contains('Helse / apotek')) {
      results.add(
        const _StoreSuggestion(
          title: 'Apotek og helse',
          why: 'Bra match for solkrem, toalettsaker og småting som alltid mangler før tur.',
          imageAsset: 'assets/images/travel/need_sunscreen.jpg',
          hint: 'Solkrem, hygiene, reiseapotek',
          pointsLabel: 'Småkjøp med nytte',
        ),
      );
    }

    if (categories.contains('Sport / fritid') ||
        categories.contains('Sport') ||
        categories.contains('Vinterutstyr')) {
      results.add(
        const _StoreSuggestion(
          title: 'Sport og fritid',
          why: 'Passer for strandutstyr, vinterutstyr og aktiv ferie med barn.',
          imageAsset: 'assets/images/travel/need_sport.jpg',
          hint: 'Strand, vinter, fritid, aktivitet',
          pointsLabel: 'God kampanjematch',
        ),
      );
    }

    if (categories.contains('Klær') || categories.contains('Sko / klær')) {
      results.add(
        const _StoreSuggestion(
          title: 'Klær og sko',
          why: 'Relevant for badetøy, gåsko, lette ferieklær og familiekjøp.',
          imageAsset: 'assets/images/travel/need_swimwear.jpg',
          hint: 'Badetøy, sko, sommerklær',
          pointsLabel: 'Sterk familiebruk',
        ),
      );
    }

    if (categories.contains('Elektronikk')) {
      results.add(
        const _StoreSuggestion(
          title: 'Elektronikk',
          why: 'Perfekt for powerbank, ladere og småting som gjør reisen enklere.',
          imageAsset: 'assets/images/travel/need_powerbank.jpg',
          hint: 'Powerbank, lader, adapter',
          pointsLabel: 'Bra poengpotensial',
        ),
      );
    }

    if (_children > 0) {
      results.add(
        const _StoreSuggestion(
          title: 'Barn og familie',
          why: 'Praktisk for snacks, underholdning og ting som gjør reisen roligere for barna.',
          imageAsset: 'assets/images/travel/need_kids.jpg',
          hint: 'Barn, snacks, aktiviteter',
          pointsLabel: 'Høy nytteverdi',
        ),
      );
    }

    if (results.isEmpty) {
      results.add(
        _StoreSuggestion(
          title: 'Relevante butikker i appen',
          why: 'Se etter butikktyper som matcher familiens behov før reisen.',
          imageAsset: 'assets/images/travel/need_generic.jpg',
          hint: hints.join(', '),
          pointsLabel: 'Generell match',
        ),
      );
    }

    return results.take(6).toList();
  }

  int _suggestedTargetPoints() {"""

match = pattern.search(text)
if not match:
    print("ERROR: Could not replace _buildStoreSuggestions block")
    raise SystemExit(1)

text = text[:match.start()] + replacement + text[match.end():]

# 3) Bytt butikkseksjonen i build med visuelle kort
old_section = """              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Butikktyper som passer best',
                        style: _sectionTitleStyle(context),
                      ),
                      const SizedBox(height: 10),
                      for (final store in storeSuggestions) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.storefront_outlined, color: Color(0xFF0F6B73)),
                          title: Text(store.title),
                          subtitle: Text(store.why),
                        ),
                        const Divider(height: 1),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Live-blokken over viser feed/fallback direkte.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF28424A),
                                              fontWeight: FontWeight.w600,
                                            ),
                      ),
                    ],
                  ),
                ),
              ),"""

new_section = """              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Butikktyper som passer best',
                        style: _sectionTitleStyle(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Disse kortene viser hvor familien sannsynligvis bør handle først.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF2E4951),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final store in storeSuggestions) ...[
                        _StoreSuggestionCard(store: store),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),"""

if old_section not in text:
    print("ERROR: Could not find old store section")
    raise SystemExit(1)

text = text.replace(old_section, new_section, 1)

# 4) Legg til widget for butikkkort
helper_widget = """
class _StoreSuggestionCard extends StatelessWidget {
  final _StoreSuggestion store;

  const _StoreSuggestionCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.asset(
                store.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1B6B73),
                          Color(0xFF0F3D5E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF142D34),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  store.why,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1F3941),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniTag(
                      label: store.hint,
                      background: const Color(0xFFE7F1F7),
                      foreground: const Color(0xFF1E4B59),
                    ),
                    _MiniTag(
                      label: store.pointsLabel,
                      background: const Color(0xFFF2E3BE),
                      foreground: const Color(0xFF6C5320),
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
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
"""

if "class _StoreSuggestionCard extends StatelessWidget" not in text:
    anchor = "class _BrandBadge extends StatelessWidget {"
    if anchor in text:
        text = text.replace(anchor, helper_widget + "\n" + anchor, 1)
    else:
        text = text.rstrip() + "\n\n" + helper_widget + "\n"

if text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 744 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
