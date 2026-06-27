#!/bin/bash
set -e
TARGET="lib/pages/bonusvarsel_alerts_page.dart"

cp "$TARGET" "$TARGET.bak_info_dialog_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 - << 'PYTHON'
with open('lib/pages/bonusvarsel_alerts_page.dart', 'r') as f:
    content = f.read()

# Erstatt den store info-boksen med en kompakt overskrift + ℹ️ knapp
old = """          _h2("✈️ Telegram-varsler"),
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

new = """          Row(children: [
            _h2("✈️ Telegram-varsler"),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showTelegramHelp,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, size: 18, color: Color(0xFF60A5FA)),
              ),
            ),
          ]),
          const SizedBox(height: 8),"""

if old in content:
    content = content.replace(old, new)
    print('✅ Info-knapp lagt til')
else:
    print('⚠️  Fant ikke info-boks – sjekk manuelt')

# Legg til _showTelegramHelp metode foran _step
old_step = "  Widget _step(String num, String text) =>"
new_step = """  void _showTelegramHelp() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0B1728),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.telegram, color: Color(0xFF60A5FA)),
                const SizedBox(width: 8),
                const Expanded(child: Text("Telegram-varsler / Telegram alerts",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 12),
              const Text("🇳🇴 Norsk",
                  style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              _step("1", "Åpne Telegram og søk etter @bonusvarsel_bot"),
              _step("2", "Trykk Start (eller send /start til boten)"),
              _step("3", "Skriv inn @bonusvarsel_bot i feltet under"),
              _step("4", "Trykk Lagre – du er klar! 🎉"),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 8),
              const Text("🇬🇧 English",
                  style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              _step("1", "Open Telegram and search for @bonusvarsel_bot"),
              _step("2", "Tap Start (or send /start to the bot)"),
              _step("3", "Enter @bonusvarsel_bot in the field below"),
              _step("4", "Tap Save – you're all set! 🎉"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String text) =>"""

if old_step in content:
    content = content.replace(old_step, new_step)
    print('✅ _showTelegramHelp dialog lagt til')
else:
    print('⚠️  Fant ikke _step')

with open('lib/pages/bonusvarsel_alerts_page.dart', 'w') as f:
    f.write(content)
PYTHON
