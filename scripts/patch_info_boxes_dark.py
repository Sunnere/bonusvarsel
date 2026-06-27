#!/usr/bin/env python3
import os

# ── 1. TRAVEL PAGE patches ───────────────────────────────────────────────────
travel_path = os.path.expanduser('~/bonusvarsel/lib/pages/travel_page.dart')
with open(travel_path, 'r') as f:
    travel = f.read()
with open(travel_path + '.bak_info', 'w') as f:
    f.write(travel)

patches = []

# Legg til PremiumPage import
patches.append((
    "import '../services/ai_service.dart';",
    "import '../services/ai_service.dart';\nimport 'premium_page.dart';",
))

# Flytt poeng-seksjon opp — endre rekkefølgen i build()
patches.append((
    """            _reisemaalSection(),
            const SizedBox(height: 12),
            _kabinetypeSection(),
            const SizedBox(height: 12),
            _poengStatusSection(),
            const SizedBox(height: 12),
            _opptjeningSection(),""",
    """            _reisemaalSection(),
            const SizedBox(height: 12),
            _poengStatusSection(),
            const SizedBox(height: 12),
            _kabinetypeSection(),
            const SizedBox(height: 12),
            _opptjeningSection(),""",
))

# Oppdater poeng-seksjon tittel og legg til info-knapp
patches.append((
    "  Widget _poengStatusSection() {\n    return _card(\n      title: '🏆 Dine EuroBonus-poeng nå',",
    "  Widget _poengStatusSection() {\n    return _card(\n      title: '🏆 Dine EuroBonus-poeng nå',\n      info: 'Logg inn på sas.no/eurobonus eller åpne SAS-appen. Poengene dine vises på forsiden under «Min konto». Skriv inn tallet her så regner vi ut hva du mangler til drømmeturen.',",
))

# Oppdater reisemål-seksjon med info
patches.append((
    "  Widget _reisemaalSection() {\n    return _card(\n      title: '🌍 Reisemål og reisefølge',",
    "  Widget _reisemaalSection() {\n    return _card(\n      title: '🌍 Reisemål og reisefølge',\n      info: 'Skriv inn destinasjonen din, f.eks. Bangkok eller London. Legg til alle som skal reise – vi regner ut poeng for hele familien. Barn 2–11 år koster 75% av voksen-prisen.',",
))

# Oppdater kabintype-seksjon med info
patches.append((
    "  Widget _kabinetypeSection() {\n    final zone = _EbCost.zoneFor(_dest);\n    final cabins = ['Economy', 'Premium', 'Business'];\n    return _card(\n      title: '💺 Kabintype',",
    "  Widget _kabinetypeSection() {\n    final zone = _EbCost.zoneFor(_dest);\n    final cabins = ['Economy', 'Premium', 'Business'];\n    return _card(\n      title: '💺 Kabintype',\n      info: 'Economy er standard bonusreise og koster færrest poeng. Premium Economy er litt dyrere men mer komfortabel. Business koster dobbelt men du sitter i flat seng. Poengene vist er per person, én vei.',",
))

# Oppdater opptjening-seksjon med info
patches.append((
    "  Widget _opptjeningSection() {",
    "  // ignore: unused_element\n  Widget _opptjeningSection() {",
))
patches.append((
    "  // ignore: unused_element\n  Widget _opptjeningSection() {",
    "  Widget _opptjeningSection() {",
))
patches.append((
    "    return _card(\n      title: '📈 Hvor raskt tjener du poeng?',",
    "    return _card(\n      title: '📈 Hvor raskt tjener du poeng?',\n      info: 'Dra i slideren for å justere hva du bruker på kortet per måned. Vi regner ut hvor lang tid det tar å nå poengs målet ditt. Husk: bruk Amex der det aksepteres for 20p/100kr.',",
))

# Oppdater AI-slagplan med premium-melding og lenker
patches.append((
    "  Widget _slagplanSection() {\n    return _card(\n      title: '🤖 AI-slagplan',",
    "  Widget _slagplanSection() {\n    return _card(\n      title: '🤖 AI-slagplan',\n      info: 'AI-en leser kortene dine, poengstatus, reisemål og favorittbutikker – og lager en personlig plan for å nå drømmeturen din raskest mulig.',",
))

# Erstatt Premium-upsell teksten med full versjon + lenker
patches.append((
    """        if (!EntitlementService.instance.isPremium) ...[
          const SizedBox(height: 8),
          const Text('💡 Premium: ubegrenset AI-analyse og personlige varsler',
            style: TextStyle(color: _warning, fontSize: 12)),
        ],""",
    """        if (!EntitlementService.instance.isPremium) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PremiumPage())),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _warning.withValues(alpha: 0.4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Text('⭐', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('Lås opp full AI-slagplan',
                    style: TextStyle(color: _warning,
                      fontWeight: FontWeight.w900, fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                const Text('Premium – 49 kr/mnd:',
                  style: TextStyle(color: _textSoft,
                    fontWeight: FontWeight.w800, fontSize: 13)),
                const Text(
                  '• Ubegrenset AI-analyse\\n'
                  '• Personlige varsler på e-post og Telegram\\n'
                  '• 5 Trumf Netthandel-favoritter\\n'
                  '• 5 SAS Online Shopping-favoritter',
                  style: TextStyle(color: _textMuted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 8),
                const Text('Elite – 99 kr/mnd:',
                  style: TextStyle(color: _primary,
                    fontWeight: FontWeight.w800, fontSize: 13)),
                const Text(
                  '• Alt i Premium\\n'
                  '• 10 favoritter per program\\n'
                  '• SAS Bonusreise-oversikt\\n'
                  '• SkyTeam-flyselskaper (Air France, KLM, Delta)\\n'
                  '• VIP-varsler og concierge-support',
                  style: TextStyle(color: _textMuted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _warning.withValues(alpha: 0.5)),
                  ),
                  child: const Center(child: Text('Se alle planer →',
                    style: TextStyle(color: _warning,
                      fontWeight: FontWeight.w900, fontSize: 13))),
                ),
              ]),
            ),
          ),
        ],""",
))

# Oppdater _card til å støtte info-parameter
patches.append((
    """  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
          color: _textSoft, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }""",
    """  Widget _card({required String title, required List<Widget> children, String? info}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(
            color: _textSoft, fontWeight: FontWeight.w900, fontSize: 15))),
          if (info != null)
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF0B1728),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Text(title, style: const TextStyle(
                        color: _text, fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 12),
                      Text(info, style: const TextStyle(
                        color: _textMuted, fontSize: 14, height: 1.6)),
                    ]),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.info_outline_rounded,
                  color: _textMuted, size: 18)),
            ),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }""",
))

content = travel
ok = 0
fail = 0
for old, new in patches:
    if old in content:
        content = content.replace(old, new, 1)
        ok += 1
    else:
        print(f"  ⚠️  Ikke funnet: {old[:60].strip()!r}")
        fail += 1

with open(travel_path, 'w') as f:
    f.write(content)
print(f"travel_page: ✅ {ok}  ❌ {fail}")

# ── 2. CARDS PAGE – mørkt tema (full rewrite av bakgrunner) ──────────────────
cards_path = os.path.expanduser('~/bonusvarsel/lib/pages/cards_page.dart')
with open(cards_path, 'r') as f:
    cards = f.read()
with open(cards_path + '.bak_dark2', 'w') as f:
    f.write(cards)

card_patches = [
    # Scaffold
    ('backgroundColor: const Color(0xFFCFE2F3),',
     'backgroundColor: const Color(0xFF06111F),'),
    # AppBar
    ('backgroundColor: const Color(0xFF0F2A6E),',
     'backgroundColor: const Color(0xFF06111F),'),
    # Hero gradient
    ('colors: [Color(0xFF0F2A6E), Color(0xFF1D4ED8)],',
     'colors: [Color(0xFF0D1F3C), Color(0xFF1D4ED8)],'),
    # Annonseplass boks
    ('color: Colors.white,\n              borderRadius: BorderRadius.circular(12),\n              border: Border.all(color: const Color(0xFFBFDBFE)),',
     'color: const Color(0xFF122033),\n              borderRadius: BorderRadius.circular(12),\n              border: Border.all(color: const Color(0xFF2F435C)),'),
    # Annonse tekst
    ('style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12,',
     'style: TextStyle(color: const Color(0xFFCBD5E1), fontSize: 12,'),
    # Info-boks
    ('color: Colors.white,\n              borderRadius: BorderRadius.circular(14),\n              border: Border.all(color: const Color(0xFFBFDBFE)),',
     'color: const Color(0xFF0B1728),\n              borderRadius: BorderRadius.circular(14),\n              border: Border.all(color: const Color(0xFF2F435C)),'),
    # Info-boks tittel
    ("style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 14)),",
     "style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),"),
    # Info-boks tekst
    ('style: TextStyle(color: Colors.black54, height: 1.55, fontSize: 13)),',
     'style: TextStyle(color: const Color(0xFFCBD5E1), height: 1.55, fontSize: 13)),'),
    # Kort-boks hvit bakgrunn
    ('color: isSelected ? card.activeBg : Colors.white,',
     'color: isSelected ? card.activeBg : const Color(0xFF0B1728),'),
    # Kort-boks ramme
    ('color: isSelected ? card.activeColor : const Color(0xFFBFDBFE), width: isSelected ? 2 : 1),',
     'color: isSelected ? card.activeColor : const Color(0xFF2F435C), width: isSelected ? 2 : 1),'),
    # Logo-boks bakgrunn
    ('color: isSelected ? card.activeBg : const Color(0xFFF0F6FF),',
     'color: isSelected ? card.activeBg : const Color(0xFF122033),'),
    # Kortnavn
    ('style: const TextStyle(color: Colors.black87,\n                      fontWeight: FontWeight.w900, fontSize: 14))),',
     'style: const TextStyle(color: Colors.white,\n                      fontWeight: FontWeight.w900, fontSize: 14))),'),
    # Beskrivelse
    ('style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),',
     'style: const TextStyle(color: const Color(0xFFCBD5E1), fontSize: 13, height: 1.4)),'),
    # Velg-knapp inaktiv
    ('backgroundColor: isSelected ? card.activeColor : const Color(0xFFEFF6FF),\n                    foregroundColor: isSelected ? Colors.white : card.activeColor,',
     'backgroundColor: isSelected ? card.activeColor : const Color(0xFF122033),\n                    foregroundColor: isSelected ? Colors.white : card.activeColor,'),
    # Se kort bakgrunn
    ('backgroundColor: Colors.white,\n                  side: BorderSide(color: card.borderColor, width: 1.5),',
     'backgroundColor: const Color(0xFF122033),\n                  side: BorderSide(color: card.borderColor, width: 1.5),'),
]

c_ok = 0
c_fail = 0
cards_content = cards
for old, new in card_patches:
    if old in cards_content:
        cards_content = cards_content.replace(old, new, 1)
        c_ok += 1
    else:
        print(f"  ⚠️  cards: {old[:55].strip()!r}")
        c_fail += 1

with open(cards_path, 'w') as f:
    f.write(cards_content)
print(f"cards_page: ✅ {c_ok}  ❌ {c_fail}")

import subprocess
r = subprocess.run(
    ['flutter', 'analyze',
     'lib/pages/travel_page.dart',
     'lib/pages/cards_page.dart'],
    capture_output=True, text=True,
    cwd=os.path.expanduser('~/bonusvarsel'))
errors = [l for l in r.stdout.splitlines() if 'error' in l.lower()]
if errors:
    for e in errors[:8]: print(f"  ❌ {e}")
else:
    print("  ✅ Ingen Dart-feil")
