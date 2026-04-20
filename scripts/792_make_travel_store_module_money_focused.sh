#!/usr/bin/env bash
set -euo pipefail

echo "==> 792_make_travel_store_module_money_focused"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_792")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

old_data = """  List<Map<String, dynamic>> _travelStoreCardsForUse() {
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
"""

new_data = """  List<Map<String, dynamic>> _travelStoreCardsForUse() {
    switch (_selectedTravelUse) {
      case 'Fly':
        return <Map<String, dynamic>>[
          {
            'icon': Icons.luggage_rounded,
            'title': 'Bagasje og kofferter',
            'subtitle': 'Gir ofte høy verdi før avreise når familien trenger mer plass, bedre pakking og smartere organisering.',
            'tags': <String>['Fly', 'Bagasje', 'Familie'],
            'bonus': 'Høy bonus før fly',
            'badge': 'Mest relevant nå',
          },
          {
            'icon': Icons.power_rounded,
            'title': 'Elektronikk og lading',
            'subtitle': 'Sterk kandidat for poengfangst før reisen med powerbank, adapter, hodetelefoner og ladere.',
            'tags': <String>['Fly', 'Elektronikk', 'Lading'],
            'bonus': 'Bra poengverdi',
            'badge': 'Populært før avreise',
          },
          {
            'icon': Icons.health_and_safety_outlined,
            'title': 'Apotek og reisehelse',
            'subtitle': 'Praktiske kjøp som ofte glemmes, men som kan gi god bonus når du samler alt før turen.',
            'tags': <String>['Apotek', 'Helse', 'Praktisk'],
            'bonus': 'Trygg verdi',
            'badge': 'Smart siste kjøp',
          },
        ];
      case 'Hotell':
        return <Map<String, dynamic>>[
          {
            'icon': Icons.checkroom_rounded,
            'title': 'Klær og sommerutstyr',
            'subtitle': 'Typisk kategori med god verdi før hotellferie når du samler klær, badetøy og sommerting.',
            'tags': <String>['Hotell', 'Klær', 'Sommer'],
            'bonus': 'Bra bonus nå',
            'badge': 'Mest brukt før hotell',
          },
          {
            'icon': Icons.bed_rounded,
            'title': 'Komfort og opphold',
            'subtitle': 'Praktiske oppgraderinger før reisen som kan gi mer verdi per kjøp enn små spredte handler.',
            'tags': <String>['Hotell', 'Komfort', 'Familie'],
            'bonus': 'Stabil poengverdi',
            'badge': 'God oppholdsverdi',
          },
          {
            'icon': Icons.face_retouching_natural,
            'title': 'Hudpleie og toiletries',
            'subtitle': 'Smart kategori å samle før hotellopphold når du vil få bonus på ting du uansett trenger.',
            'tags': <String>['Hudpleie', 'Toalettartikler', 'Reise'],
            'bonus': 'Enkel bonusfangst',
            'badge': 'Praktisk før innsjekk',
          },
        ];
      case 'Leiebil':
        return <Map<String, dynamic>>[
          {
            'icon': Icons.directions_car_filled_rounded,
            'title': 'Biltilbehør og komfort',
            'subtitle': 'God kategori før kjøretur når du vil hente verdi på komfort, organisering og små bilkjøp.',
            'tags': <String>['Leiebil', 'Komfort', 'Bil'],
            'bonus': 'Høy nytteverdi',
            'badge': 'Best for roadtrip',
          },
          {
            'icon': Icons.devices_other_rounded,
            'title': 'Elektronikk til reisen',
            'subtitle': 'Ladere, mobilholder og kabler kan gi god verdi når du samler nødvendige kjøp før avreise.',
            'tags': <String>['Elektronikk', 'Bil', 'Lading'],
            'bonus': 'Bra bonus nå',
            'badge': 'Sterk match',
          },
          {
            'icon': Icons.child_care_rounded,
            'title': 'Familie og barn på tur',
            'subtitle': 'Snacks, organisering og praktiske ting kan bli en fin bonuskategori før lengre familietur.',
            'tags': <String>['Familie', 'Barn', 'Praktisk'],
            'bonus': 'Smart familieverdi',
            'badge': 'Relevant før avgang',
          },
        ];
      default:
        return <Map<String, dynamic>>[];
    }
  }
"""

if old_data not in text:
    print("❌ Fant ikke _travelStoreCardsForUse-blokka eksakt")
    print("Kjør dette og send resultatet:")
    print("  sed -n '1,240p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_data, new_data, 1)

old_card = """  Widget _travelStoreCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> tags,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FCFD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE8EB),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF103562),
                  Color(0xFF1294A4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220F4C5C),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF183038),
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF597079),
                    fontWeight: FontWeight.w600,
                    height: 1.34,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFD7E7EA),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2C525B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF123A69),
                            Color(0xFF0E7B8B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x220D5C72),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Se butikker',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Best for $_selectedTravelUse',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6D848B),
                        fontWeight: FontWeight.w800,
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

new_card = """  Widget _travelStoreCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> tags,
    required String bonus,
    required String badge,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FCFD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE8EB),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF103562),
                  Color(0xFF1294A4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220F4C5C),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF183038),
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2C9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFF0D37B)),
                      ),
                      child: Text(
                        bonus,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF805B00),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF597079),
                    fontWeight: FontWeight.w600,
                    height: 1.34,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFD7E7EA),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2C525B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF123A69),
                            Color(0xFF0E7B8B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x220D5C72),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Se beste tilbud',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      badge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6D848B),
                        fontWeight: FontWeight.w800,
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

if old_card not in text:
    print("❌ Fant ikke _travelStoreCard-blokka eksakt")
    print("Kjør dette og send resultatet:")
    print("  sed -n '1,320p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_card, new_card, 1)

old_map = """          ...cards.map(
            (card) => _travelStoreCard(
              context,
              icon: card['icon'] as IconData,
              title: card['title'] as String,
              subtitle: card['subtitle'] as String,
              tags: (card['tags'] as List<String>),
            ),
          ),
"""

new_map = """          ...cards.map(
            (card) => _travelStoreCard(
              context,
              icon: card['icon'] as IconData,
              title: card['title'] as String,
              subtitle: card['subtitle'] as String,
              tags: (card['tags'] as List<String>),
              bonus: card['bonus'] as String,
              badge: card['badge'] as String,
            ),
          ),
"""

if old_map not in text:
    print("❌ Fant ikke map-kallet til _travelStoreCard")
    print("Kjør dette og send resultatet:")
    print("  sed -n '320,460p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_map, new_map, 1)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ Gjorde butikkmodulen mer bonus- og tilbudsfokusert")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
