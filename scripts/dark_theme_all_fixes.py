#!/usr/bin/env python3
import os

# ─────────────────────────────────────────────────────────────────────────────
# 1. CARDS PAGE – mørkt tema + maks 1 SAS / 1 Trumf
# ─────────────────────────────────────────────────────────────────────────────
cards_path = os.path.expanduser('~/bonusvarsel/lib/pages/cards_page.dart')
with open(cards_path, 'r') as f:
    orig = f.read()
with open(cards_path + '.bak_dark', 'w') as f:
    f.write(orig)

# Fargekonstanter fra AppTheme
BG        = 'Color(0xFF06111F)'
SURFACE   = 'Color(0xFF0B1728)'
SURFACE2  = 'Color(0xFF122033)'
BORDER    = 'Color(0xFF2F435C)'
PRIMARY   = 'Color(0xFF60A5FA)'
PRIMARY_D = 'Color(0xFF1D4ED8)'
TEXT      = 'Colors.white'
TEXT_SOFT = 'Color(0xFFE2E8F0)'
TEXT_MUTED= 'Color(0xFFCBD5E1)'
SUCCESS   = 'Color(0xFF34D399)'

patches = []

# Scaffold bakgrunn
patches.append((
    'backgroundColor: const Color(0xFFCFE2F3),',
    f'backgroundColor: const {BG},',
))

# AppBar
patches.append((
    'backgroundColor: const Color(0xFF0F2A6E),',
    f'backgroundColor: const {BG},',
))

# Hero gradient
patches.append((
    'colors: [Color(0xFF0F2A6E), Color(0xFF1D4ED8)],',
    f'colors: [Color(0xFF0D1F3C), {PRIMARY_D}],',
))
patches.append((
    'BoxShadow(color: Color(0x440F2A6E), blurRadius: 12, offset: Offset(0, 4))',
    'BoxShadow(color: Color(0x441D4ED8), blurRadius: 12, offset: Offset(0, 4))',
))

# Annonseplass
patches.append((
    '              color: Colors.white,\n              borderRadius: BorderRadius.circular(12),\n              border: Border.all(color: const Color(0xFFBFDBFE)),',
    f'              color: const {SURFACE2},\n              borderRadius: BorderRadius.circular(12),\n              border: Border.all(color: const {BORDER}),',
))
patches.append((
    "style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12,",
    f"style: TextStyle(color: const {TEXT_MUTED}, fontSize: 12,",
))

# Seksjonsheder farger
patches.append((
    "_sectionHeader('SAS EuroBonus', const Color(0xFF0F2A6E), isAmex: false),",
    f"_sectionHeader('SAS EuroBonus', const {PRIMARY}, isAmex: false),",
))
patches.append((
    "_sectionHeader('Trumf', const Color(0xFF007A3D), isAmex: false),",
    f"_sectionHeader('Trumf', const {SUCCESS}, isAmex: false),",
))

# Info-boks
patches.append((
    "              color: Colors.white,\n              borderRadius: BorderRadius.circular(14),\n              border: Border.all(color: const Color(0xFFBFDBFE)),",
    f"              color: const {SURFACE},\n              borderRadius: BorderRadius.circular(14),\n              border: Border.all(color: const {BORDER}),",
))
patches.append((
    "              Text('ℹ️  Slik fungerer kortvalget (multi)',\n                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 14)),\n              SizedBox(height: 8),\n              Text(\n                '• Velg ett eller flere kort – alle telles med i AI-slagplanen\\n'\n                '• Siste valgte kort er primært for enkel kalkulator\\n'",
    f"              Text('ℹ️  Velg kort',\n                style: TextStyle(color: {TEXT}, fontWeight: FontWeight.w900, fontSize: 14)),\n              SizedBox(height: 8),\n              Text(\n                '• Velg ett SAS-kort og/eller ett Trumf-kort\\n'\n                '• AI-slagplanen bruker alle valgte kort\\n'",
))
patches.append((
    "                  '• Faktisk opptjening avhenger av butikk og tilbud\\n'\n                  '• Trykk \"Se kort\" for å søke om eller lese mer',\n                  style: TextStyle(color: Colors.black54, height: 1.55, fontSize: 13)),",
    f"                  '• Faktisk opptjening avhenger av butikk og tilbud\\n'\n                  '• Trykk \"Se kort\" for å søke om eller lese mer',\n                  style: TextStyle(color: const {TEXT_MUTED}, height: 1.55, fontSize: 13)),",
))

# _CardTile – kort-boks bakgrunn
patches.append((
    '        color: isSelected ? card.activeBg : Colors.white,',
    f'        color: isSelected ? card.activeBg : const {SURFACE},',
))
patches.append((
    '          color: isSelected ? card.activeColor : const Color(0xFFBFDBFE), width: isSelected ? 2 : 1),',
    f'          color: isSelected ? card.activeColor : const {BORDER}, width: isSelected ? 2 : 1),',
))

# Logo-boks
patches.append((
    '                  color: isSelected ? card.activeBg : const Color(0xFFF0F6FF),',
    f'                  color: isSelected ? card.activeBg : const {SURFACE2},',
))

# Kortnavn tekst
patches.append((
    "                    style: const TextStyle(color: Colors.black87,\n                      fontWeight: FontWeight.w900, fontSize: 14))),",
    f"                    style: const TextStyle(color: {TEXT},\n                      fontWeight: FontWeight.w900, fontSize: 14))),",
))

# Beskrivelsestekst
patches.append((
    '              style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),',
    f'              style: const TextStyle(color: const {TEXT_MUTED}, fontSize: 13, height: 1.4)),',
))

# Velg-knapp inaktiv
patches.append((
    '                    backgroundColor: isSelected ? card.activeColor : const Color(0xFFEFF6FF),\n                    foregroundColor: isSelected ? Colors.white : card.activeColor,',
    f'                    backgroundColor: isSelected ? card.activeColor : const {SURFACE2},\n                    foregroundColor: isSelected ? {TEXT} : card.activeColor,',
))

# Se kort-knapp
patches.append((
    '                  backgroundColor: Colors.white,\n                  side: BorderSide(color: card.borderColor, width: 1.5),',
    f'                  backgroundColor: const {SURFACE2},\n                  side: BorderSide(color: card.borderColor, width: 1.5),',
))

# _toggleCard: begrens til 1 SAS + 1 Trumf
patches.append((
    '  Future<void> _toggleCard(String id, int rate) async {\n    final isNowSelected = !_selectedCardIds.contains(id);',
    '''  Future<void> _toggleCard(String id, int rate) async {
    final isNowSelected = !_selectedCardIds.contains(id);
    // Maks 1 SAS-kort og 1 Trumf-kort
    if (isNowSelected) {
      final isSas = id.startsWith('sas');
      final isTrumf = id.startsWith('trumf');
      final conflicting = _selectedCardIds.where((existing) =>
          (isSas && existing.startsWith('sas')) ||
          (isTrumf && existing.startsWith('trumf'))).toList();
      for (final old in conflicting) {
        await UserState.removeSelectedCard(old);
        _selectedCardIds.remove(old);
      }
    }''',
))

content = orig
ok = 0
fail = 0
for old, new in patches:
    if old in content:
        content = content.replace(old, new, 1)
        ok += 1
    else:
        print(f"  ⚠️  Ikke funnet: {old[:55].strip()!r}")
        fail += 1

with open(cards_path, 'w') as f:
    f.write(content)
print(f"cards_page: ✅ {ok}  ❌ {fail}")


# ─────────────────────────────────────────────────────────────────────────────
# 2. AI SERVICE – les favoritter + bruk beste kort-rate
# ─────────────────────────────────────────────────────────────────────────────
ai_path = os.path.expanduser('~/bonusvarsel/lib/services/ai_service.dart')
with open(ai_path, 'r') as f:
    ai = f.read()
with open(ai_path + '.bak_fav', 'w') as f:
    f.write(ai)

# Legg til favoritt-lesing i getTravelPlan
old_fav = "    final cardDetails = _buildCardDetails(cardIds);"
new_fav = """    // Les favoritter fra Spar-siden
    final prefs2 = await SharedPreferences.getInstance();
    final favButikk = prefs2.getString('trumf_fav_dag') ?? 'kiwi';
    final favMobil  = prefs2.getString('trumf_fav_mob');
    final favStrom  = prefs2.getString('trumf_fav_strom');
    const butikkNavn = {'kiwi':'KIWI','meny':'MENY','spar':'SPAR','joker':'Joker','naer':'Nærbutikken'};
    final dagligvareButikk = butikkNavn[favButikk] ?? 'KIWI';
    final harTalkmore  = favMobil  == 'talkmore';
    final harFjordkraft = favStrom == 'fjordkraft';

    // Beste rate blant valgte kort
    const rateMap = {'sas_amex':20,'sas_mc':15,'sas_visa':10,'trumf_visa':10,'trumf_mc':8};
    final bestRate = cardIds.isEmpty ? 15 :
        cardIds.map((id) => rateMap[id] ?? 10).reduce((a, b) => a > b ? a : b);

    final cardDetails = _buildCardDetails(cardIds);"""

if old_fav in ai:
    ai = ai.replace(old_fav, new_fav, 1)
    print("ai_service: ✅ Favoritter lagt til")
else:
    print("ai_service: ❌ Fant ikke favoritt-injeksjonspunkt")

# Legg til favoritter i prompt
old_prompt_end = "Vær spesifikk med tall og kortenes unike fordeler.''';"
new_prompt_end = """Vær spesifikk med tall og kortenes unike fordeler.
${harTalkmore ? '\\n- Talkmore: 4% Trumf-bonus på mobilregning' : ''}
${harFjordkraft ? '\\n- Fjordkraft: 1% Trumf-bonus på strøm' : ''}

DAGLIGVAREBUTIKK: $dagligvareButikk
BESTE KORTRATE: $bestRate poeng/100 kr (bruk dette i utregninger)''';"""

if old_prompt_end in ai:
    ai = ai.replace(old_prompt_end, new_prompt_end, 1)
    print("ai_service: ✅ Favoritter og beste rate inn i prompt")
else:
    print("ai_service: ❌ Fant ikke prompt-slutt")

with open(ai_path, 'w') as f:
    f.write(ai)


# ─────────────────────────────────────────────────────────────────────────────
# 3. TRAVEL PAGE – bruk beste kort-rate i kalkulator
# ─────────────────────────────────────────────────────────────────────────────
travel_path = os.path.expanduser('~/bonusvarsel/lib/pages/travel_page.dart')
with open(travel_path, 'r') as f:
    travel = f.read()
with open(travel_path + '.bak_rate', 'w') as f:
    f.write(travel)

# Bruk beste rate blant alle valgte kort
old_rate = """    setState(() {
      _selectedCardId = id;
      _cardRatePer100 = rateInt;
      _selectedCardIds = ids.toSet();
      _isTrumfMember = trumf;
    });"""

new_rate = """    // Bruk beste rate blant alle valgte kort
    const rateMap = {'sas_amex':20,'sas_mc':15,'sas_visa':10,'trumf_visa':10,'trumf_mc':8};
    final bestRate = ids.isEmpty ? rateInt :
        ids.map((i) => rateMap[i] ?? 10).reduce((a, b) => a > b ? a : b);
    setState(() {
      _selectedCardId = id;
      _cardRatePer100 = bestRate;
      _selectedCardIds = ids.toSet();
      _isTrumfMember = trumf;
    });"""

if old_rate in travel:
    travel = travel.replace(old_rate, new_rate, 1)
    print("travel_page: ✅ Beste kortrate i kalkulator")
else:
    print("travel_page: ❌ Fant ikke rate-setState")

with open(travel_path, 'w') as f:
    f.write(travel)

# ─────────────────────────────────────────────────────────────────────────────
print()
print("Kjør: flutter run --dart-define=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
