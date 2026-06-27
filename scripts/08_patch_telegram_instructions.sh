#!/bin/bash
set -e
TARGET="lib/pages/bonusvarsel_alerts_page.dart"

cp "$TARGET" "$TARGET.bak_tg_instructions_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 - << 'PYTHON'
with open('lib/pages/bonusvarsel_alerts_page.dart', 'r') as f:
    content = f.read()

old = """          _h2("✈️ Telegram-varsler"),
          const SizedBox(height: 4),
          const Text("Legg til @BonusvarselBot og skriv inn brukernavn:",
              style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13)),"""

new = """          _h2("✈️ Telegram-varsler"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFF0B1728),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Slik setter du opp Telegram-varsler:",
                    style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700, fontSize: 13)),
                SizedBox(height: 8),
                _step("1", "Åpne Telegram og søk etter @bonusvarsel_bot"),
                _step("2", "Trykk Start (eller send /start til boten)"),
                _step("3", "Skriv inn @bonusvarsel_bot i feltet under"),
                _step("4", "Trykk Lagre – du er klar! 🎉"),
              ],
            ),
          ),
          const SizedBox(height: 10),"""

if old in content:
    content = content.replace(old, new)
    with open('lib/pages/bonusvarsel_alerts_page.dart', 'w') as f:
        f.write(content)
    print('✅ Bruksanvisning lagt til')
else:
    print('⚠️  Fant ikke teksten – sjekk manuelt')
PYTHON
python3 - << 'PYTHON'
with open('lib/pages/bonusvarsel_alerts_page.dart', 'r') as f:
    content = f.read()

old = "  Widget _seeAll("
new = """  Widget _step(String num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 20, height: 20,
        margin: const EdgeInsets.only(right: 8, top: 1),
        decoration: BoxDecoration(
          color: Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(999)),
        child: Center(child: Text(num,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)))),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.4))),
    ]),
  );

  Widget _seeAll("""

if old in content:
    content = content.replace(old, new)
    with open('lib/pages/bonusvarsel_alerts_page.dart', 'w') as f:
        f.write(content)
    print('✅ _step widget lagt til')
else:
    print('⚠️  Fant ikke _seeAll')
PYTHON
