#!/bin/bash
cp lib/pages/cards_page.dart lib/pages/cards_page.dart.bak3

# Legg til import og login-trigger øverst i _selectCard
sed -i '' "s|import 'package:url_launcher/url_launcher.dart';|import 'package:url_launcher/url_launcher.dart';\nimport 'package:firebase_auth/firebase_auth.dart';\nimport '../pages/login_page.dart';|" lib/pages/cards_page.dart

# Erstatt _selectCard med versjon som sjekker innlogging
cat >> /tmp/patch_cards.py << 'PYTHON'
import re

with open('lib/pages/cards_page.dart', 'r') as f:
    content = f.read()

old = '''  Future<void> _selectCard(String id, int rate) async {
    await UserState.setSelectedCard(id, rate.toDouble());
    if (!mounted) return;
    setState(() => _selectedCardId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${CardCatalog.nameFor(id)} valgt som aktivt kort'),
        duration: const Duration(seconds: 2),
      ),
    );
  }'''

new = '''  Future<void> _selectCard(String id, int rate) async {
    // Krev innlogging for å velge kort
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onSuccess: () async {
              await UserState.setSelectedCard(id, rate.toDouble());
              if (!mounted) return;
              setState(() => _selectedCardId = id);
            },
          ),
        ),
      );
      return;
    }

    await UserState.setSelectedCard(id, rate.toDouble());
    if (!mounted) return;
    setState(() => _selectedCardId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(CardCatalog.nameFor(id) + \' valgt som aktivt kort\'),
        duration: const Duration(seconds: 2),
      ),
    );
  }'''

content = content.replace(old, new)

with open('lib/pages/cards_page.dart', 'w') as f:
    f.write(content)

print("✅ Login-sjekk lagt til i _selectCard")
PYTHON

python3 /tmp/patch_cards.py

echo ""
echo "=== Bygger for å sjekke feil ==="
flutter build ios --debug --no-codesign 2>&1 | grep -E "error:|warning:|✓|Compiling" | head -20

echo ""
echo "=== Ferdig ==="
