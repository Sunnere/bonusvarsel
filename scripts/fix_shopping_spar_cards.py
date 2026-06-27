#!/usr/bin/env python3
import os

# ── 1. EB_SHOPPING_PAGE: Trumf-kategorier åpner URL + fiks Gina Tricot ──────
shop_path = os.path.expanduser('~/bonusvarsel/lib/pages/eb_shopping_page.dart')
with open(shop_path, 'r') as f:
    shop = f.read()
with open(shop_path + '.bak_fixes', 'w') as f:
    f.write(shop)

# Fiks Trumf-kategorier med URLer
shop = shop.replace(
    """  static const _trumfCats = [
    {"name": "Alle kampanjer", "icon": "⭐"},
    {"name": "Reise",          "icon": "🌍"},
    {"name": "Mote",           "icon": "👗"},
    {"name": "Sport",          "icon": "🏅"},
    {"name": "Elektronikk",    "icon": "📱"},
    {"name": "Bolig",          "icon": "🏠"},
  ];""",
    """  static const _trumfCats = [
    {"name": "Alle kampanjer", "icon": "⭐", "url": "https://trumfnetthandel.no/"},
    {"name": "Reise",          "icon": "🌍", "url": "https://trumfnetthandel.no/kategori/reise"},
    {"name": "Mote",           "icon": "👗", "url": "https://trumfnetthandel.no/kategori/mote"},
    {"name": "Sport",          "icon": "🏅", "url": "https://trumfnetthandel.no/kategori/sport"},
    {"name": "Elektronikk",    "icon": "📱", "url": "https://trumfnetthandel.no/kategori/elektronikk"},
    {"name": "Bolig",          "icon": "🏠", "url": "https://trumfnetthandel.no/kategori/bolig"},
  ];""")

# Trumf-kategori onTap: åpne URL i tillegg til å sette index
shop = shop.replace(
    '                  onTap: () => setState(() => _trumfCatIdx = i),',
    '                  onTap: () { setState(() => _trumfCatIdx = i); _open((_trumfCats[i]["url"] ?? "https://trumfnetthandel.no/") as String); },')

# SAS-kategori onTap: åpne URL i tillegg til index
shop = shop.replace(
    '                  onTap: () => setState(() => _sasCatIdx = i),',
    '                  onTap: () { setState(() => _sasCatIdx = i); _open((_sasCats[i]["url"] ?? "https://onlineshopping.flysas.com/nb-NO") as String); },')

# Fiks Gina Tricot URL (404 → riktig URL)
shop = shop.replace(
    '{"name": "Gina Tricot",     "pts": "60", "camp": true,  "slug": "gina-tricot"}',
    '{"name": "Gina Tricot",     "pts": "60", "camp": true,  "slug": "gina-tricot", "url": "https://trumfnetthandel.no/butikk/gina-tricot"}')

# Fiks "Handle på nett med bonus" → "Handle på nett for bonus"
shop = shop.replace(
    '"Handle på nett med bonus"',
    '"Handle på nett – tjen bonus"')

# Legg til info-tekst under "Handle på nett"
shop = shop.replace(
    '"Gå til butikken via appen – bonus registreres automatisk"',
    '"Trykk på en kategori eller butikk for å gå direkte dit. Bonus registreres automatisk når du handler via lenken – du trenger ikke gjøre noe ekstra."')

with open(shop_path, 'w') as f:
    f.write(shop)
print("✅ eb_shopping_page: Trumf-kategorier, Gina Tricot, tekst")

# ── 2. TRUMF_KALKULATOR: ℹ️ på forbruk-slider + logoer i favoritter ─────────
kalk_path = os.path.expanduser('~/bonusvarsel/lib/pages/trumf_kalkulator_page.dart')
with open(kalk_path, 'r') as f:
    kalk = f.read()
with open(kalk_path + '.bak_fixes', 'w') as f:
    f.write(kalk)

# Legg til ℹ️ info-knapp ved siden av "Ditt månedlige forbruk"
kalk = kalk.replace(
    "        _secLabel('Ditt månedlige forbruk'),",
    """        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _secLabel('Ditt månedlige forbruk'),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF0B1728),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Hvorfor er dette viktig?',
                    style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 12),
                  const Text(
                    'Dette er det du handler for i dagligvarebutikken din per måned – '
                    'f.eks. KIWI, MENY eller SPAR.\\n\\n'
                    'Jo høyere beløp, desto mer Trumf-bonus tjener du. '
                    'Kalkulatoren viser deg nøyaktig hva du kan spare og hvor mange '
                    'EuroBonus-poeng du kan tjene.\\n\\n'
                    '💡 Gå til Favoritter-fanen for å velge hvilken butikk du '
                    'handler i – da blir utregningen enda mer presis!',
                    style: TextStyle(color: Color(0xFFCBD5E1),
                      fontSize: 14, height: 1.6)),
                ]),
              ),
            ),
            child: const Icon(Icons.info_outline_rounded,
              color: Color(0xFF2A9D6E), size: 18)),
        ]),""")

# Legg til logoer i favoritter-grid (erstatt emoji med tekst-logo for dagligvare)
kalk = kalk.replace(
    """        _secLabel('🛒 Hvilken dagligvarebutikk bruker du mest?'),
        const SizedBox(height: 10),
        _favGrid([
          {'id': 'kiwi',  'icon': '🟡', 'name': 'KIWI',        'pct': '1%'},
          {'id': 'meny',  'icon': '🔴', 'name': 'MENY',        'pct': '1%'},
          {'id': 'spar',  'icon': '🟢', 'name': 'SPAR',        'pct': '1%'},
          {'id': 'joker', 'icon': '🃏', 'name': 'Joker',       'pct': '1%'},
          {'id': 'naer',  'icon': '🏘', 'name': 'Nærbutikken', 'pct': '1%'},
        ], _valgtButikk,
            (id) => setState(() { _valgtButikk = id; _saveFavoritter(); })),""",
    """        _secLabel('🛒 Hvilken dagligvarebutikk bruker du mest?'),
        const SizedBox(height: 10),
        _favGridLogo([
          {'id': 'kiwi',  'color': 0xFFFFD600, 'textColor': 0xFF1A1A1A, 'name': 'KIWI',        'pct': '1%'},
          {'id': 'meny',  'color': 0xFFE4001B, 'textColor': 0xFFFFFFFF, 'name': 'MENY',        'pct': '1%'},
          {'id': 'spar',  'color': 0xFF007A3D, 'textColor': 0xFFFFFFFF, 'name': 'SPAR',        'pct': '1%'},
          {'id': 'joker', 'color': 0xFF1A1A2E, 'textColor': 0xFFFFFFFF, 'name': 'Joker',       'pct': '1%'},
          {'id': 'naer',  'color': 0xFF2563EB, 'textColor': 0xFFFFFFFF, 'name': 'Nær',         'pct': '1%'},
        ], _valgtButikk,
            (id) => setState(() { _valgtButikk = id; _saveFavoritter(); })),""")

# Legg til _favGridLogo-metoden etter _favGrid
old_favgrid_end = "  Widget _euroBox("
new_favgrid_logo = """  Widget _favGridLogo(List<Map<String, dynamic>> items, String? sel,
      ValueChanged<String> onSelect) {
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1,
      children: items.map((item) {
        final isSel = sel == item['id'];
        final bgColor = Color(item['color'] as int);
        final txtColor = Color(item['textColor'] as int);
        return GestureDetector(
          onTap: () => onSelect(item['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSel
                  ? const Color(0xFF1A8A5C).withOpacity(0.2)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSel ? const Color(0xFF1A8A5C) : Colors.white12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 48, height: 28,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(item['name'] as String,
                  style: TextStyle(color: txtColor,
                    fontWeight: FontWeight.w900, fontSize: 12))),
              ),
              const SizedBox(height: 4),
              Text(item['pct'] as String,
                style: TextStyle(fontSize: 10,
                  color: isSel ? const Color(0xFF4ADE80) : Colors.grey[500])),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _euroBox("""

kalk = kalk.replace(old_favgrid_end, new_favgrid_logo)

with open(kalk_path, 'w') as f:
    f.write(kalk)
print("✅ trumf_kalkulator: ℹ️ slider, logoer i favoritter")

# ── 3. CARDS PAGE: lysere bakgrunn ──────────────────────────────────────────
cards_path = os.path.expanduser('~/bonusvarsel/lib/pages/cards_page.dart')
with open(cards_path, 'r') as f:
    cards = f.read()
with open(cards_path + '.bak_light', 'w') as f:
    f.write(cards)

# Scaffold – litt lysere enn #06111F
cards = cards.replace(
    'backgroundColor: const Color(0xFF06111F),\n      appBar: AppBar(',
    'backgroundColor: const Color(0xFF0B1728),\n      appBar: AppBar(')

# AppBar
cards = cards.replace(
    'backgroundColor: const Color(0xFF06111F),\n        elevation: 0,\n        title: const Text(\'Kort\'',
    'backgroundColor: const Color(0xFF0B1728),\n        elevation: 0,\n        title: const Text(\'Kort\'')

# Kort-boks bakgrunn – lysere
cards = cards.replace(
    'color: isSelected ? card.activeBg : const Color(0xFF0B1728),',
    'color: isSelected ? card.activeBg : const Color(0xFF122033),')

# Logo-boks bakgrunn
cards = cards.replace(
    'color: isSelected ? card.activeBg : const Color(0xFF122033),\n                  borderRadius: BorderRadius.circular(12),',
    'color: isSelected ? card.activeBg : const Color(0xFF1A2A40),\n                  borderRadius: BorderRadius.circular(12),')

# Info-boks
cards = cards.replace(
    'color: const Color(0xFF0B1728),\n              borderRadius: BorderRadius.circular(14),',
    'color: const Color(0xFF122033),\n              borderRadius: BorderRadius.circular(14),')

# Velg-knapp inaktiv
cards = cards.replace(
    'backgroundColor: isSelected ? card.activeColor : const Color(0xFF122033),',
    'backgroundColor: isSelected ? card.activeColor : const Color(0xFF1A2A40),')

# Se kort bakgrunn
cards = cards.replace(
    'backgroundColor: const Color(0xFF122033),\n                  side: BorderSide(color: card.borderColor',
    'backgroundColor: const Color(0xFF1A2A40),\n                  side: BorderSide(color: card.borderColor')

with open(cards_path, 'w') as f:
    f.write(cards)
print("✅ cards_page: lysere bakgrunner")

import subprocess
r = subprocess.run(
    ['flutter', 'analyze',
     'lib/pages/eb_shopping_page.dart',
     'lib/pages/trumf_kalkulator_page.dart',
     'lib/pages/cards_page.dart'],
    capture_output=True, text=True,
    cwd=os.path.expanduser('~/bonusvarsel'))
errors = [l for l in r.stdout.splitlines() if 'error' in l.lower()]
if errors:
    for e in errors[:8]: print(f"  ❌ {e}")
else:
    print("  ✅ Ingen Dart-feil")

print()
print("Kjør: flutter run -d 00008110-001138643E60401E --dart-define=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
