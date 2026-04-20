#!/usr/bin/env bash
set -euo pipefail

echo "==> 790_butikkmodul_for_travel_use"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_790_butikkmodul")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

if "_buildTravelStoreModule(BuildContext context)" in text:
    print("ℹ️ Butikkmodul finnes allerede. Stopper for å unngå dobbeltpatch.")
    raise SystemExit(0)

helpers = r"""
  List<Map<String, dynamic>> _travelStoreCardsForUse() {
    switch (_selectedTravelUse) {
      case 'Fly':
        return <Map<String, dynamic>>[
          {
            'icon': Icons.luggage_rounded,
            'title': 'Bagasje og kofferter',
            'subtitle': 'Bra før flyreise når familien trenger mer plass, bedre pakking og smartere organisering.',
            'tags': <String>['Fly', 'Bagasje', 'Familie'],
          },
          {
            'icon': Icons.power_rounded,
            'title': 'Elektronikk og lading',
            'subtitle': 'Powerbank, adapter, hodetelefoner og ladere gir høy nytte før avreise.',
            'tags': <String>['Fly', 'Elektronikk', 'Lading'],
          },
          {
            'icon': Icons.health_and_safety_outlined,
            'title': 'Apotek og reisehelse',
            'subtitle': 'Solkrem, hygiene, reiseapotek og småting som ofte glemmes til flyturen.',
            'tags': <String>['Apotek', 'Helse', 'Praktisk'],
          },
        ];
      case 'Hotell':
        return <Map<String, dynamic>>[
          {
            'icon': Icons.checkroom_rounded,
            'title': 'Klær og sommerutstyr',
            'subtitle': 'Badetøy, lette klær og ting som passer hotellopphold og familieferie.',
            'tags': <String>['Hotell', 'Klær', 'Sommer'],
          },
          {
            'icon': Icons.bed_rounded,
            'title': 'Komfort og opphold',
            'subtitle': 'Nyttig for hotellnætter, familiebehov og små oppgraderinger før reisen.',
            'tags': <String>['Hotell', 'Komfort', 'Familie'],
          },
          {
            'icon': Icons.face_retouching_natural,
            'title': 'Hudpleie og toiletries',
            'subtitle': 'Smart før hotellopphold når du vil samle praktiske kjøp på ett sted.',
            'tags': <String>['Hudpleie', 'Toalettartikler', 'Reise'],
          },
        ];
      case 'Leiebil':
        return <Map<String, dynamic>>[
          {
            'icon': Icons.directions_car_filled_rounded,
            'title': 'Biltilbehør og komfort',
            'subtitle': 'Praktiske kjøp for lengre kjøreturer, barn i bilen og bedre komfort på veien.',
            'tags': <String>['Leiebil', 'Komfort', 'Bil'],
          },
          {
            'icon': Icons.devices_other_rounded,
            'title': 'Elektronikk til reisen',
            'subtitle': 'Mobilholder, ladere, kabler og småting som gjør leiebilferien enklere.',
            'tags': <String>['Elektronikk', 'Bil', 'Lading'],
          },
          {
            'icon': Icons.child_care_rounded,
            'title': 'Familie og barn på tur',
            'subtitle': 'Smart når turen trenger mer fleksibilitet, snacks, organisering og praktiske ting.',
            'tags': <String>['Familie', 'Barn', 'Praktisk'],
          },
        ];
      default:
        return <Map<String, dynamic>>[];
    }
  }

  Widget _travelStoreCard(
    BuildContext context, {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE3ECEF),
          width: 1,
        ),
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
                  Color(0xFF12396B),
                  Color(0xFF0D7D8D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF173038),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF587079),
                        fontWeight: FontWeight.w600,
                        height: 1.32,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF6F7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF2A535D),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelStoreModule(BuildContext context) {
    final cards = _travelStoreCardsForUse();

    final moduleTitle = switch (_selectedTravelUse) {
      'Fly' => 'Butikker som passer før flyreisen',
      'Hotell' => 'Butikker som passer før hotellopphold',
      'Leiebil' => 'Butikker som passer før leiebilturen',
      _ => 'Relevante butikker før reisen',
    };

    final moduleIntro = switch (_selectedTravelUse) {
      'Fly' => 'Fokus på bagasje, elektronikk og praktiske kjøp som gir verdi før avreise.',
      'Hotell' => 'Fokus på opphold, klær og ting som gir mer verdi rundt hotellferien.',
      'Leiebil' => 'Fokus på komfort, elektronikk og familiebehov for en enklere kjøretur.',
      _ => 'Velg bruk for å få riktigere butikkforslag.',
    };

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4ECEE),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moduleTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF173038),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            moduleIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5C7178),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          ...cards.map(
            (card) => _travelStoreCard(
              context,
              icon: card['icon'] as IconData,
              title: card['title'] as String,
              subtitle: card['subtitle'] as String,
              tags: (card['tags'] as List<String>),
            ),
          ),
        ],
      ),
    );
  }

"""

anchor = "double _amount()"
if anchor not in text:
    print("❌ Fant ikke anker for å sette inn helper-metoder")
    raise SystemExit(1)

text = text.replace(anchor, helpers + "\n" + anchor, 1)

widget_anchor = """              _buildTravelUseModule(context),
"""
if widget_anchor not in text:
    print("❌ Fant ikke anker etter _buildTravelUseModule(context)")
    print("Kjør og send:")
    print("  grep -n \"_buildTravelUseModule(context)\" lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(
    widget_anchor,
    """              _buildTravelUseModule(context),
              _buildTravelStoreModule(context),
""",
    1,
)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ La inn butikkmodul koblet til Fly / Hotell / Leiebil")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
