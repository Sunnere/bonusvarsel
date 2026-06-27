#!/bin/bash
set -e
TARGET="lib/pages/bonusvarsel_alerts_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Finner ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_email_tg_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 - << 'PYTHON'
with open('lib/pages/bonusvarsel_alerts_page.dart', 'r') as f:
    content = f.read()

old_email = """  Future<void> _saveEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
    setState(() { _emailValue = email; _emailSaved = true; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("E-post lagret!")));
  }"""

new_email = """  Future<void> _saveEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
    setState(() { _emailValue = email; _emailSaved = true; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'alertEmail':           email,
          'notificationsEnabled': true,
          'updatedAt':            FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore e-post feilet: $e');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("E-post lagret!")));
  }"""

old_tg = """  Future<void> _saveTelegram() async {
    final tg = _telegramCtrl.text.trim();
    if (tg.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTelegram, tg);
    setState(() { _telegramValue = tg; _telegramSaved = true; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Telegram lagret!")));
  }"""

new_tg = """  Future<void> _saveTelegram() async {
    final tg = _telegramCtrl.text.trim();
    if (tg.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTelegram, tg);
    setState(() { _telegramValue = tg; _telegramSaved = true; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'alertTelegram':        tg,
          'notificationsEnabled': true,
          'updatedAt':            FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore Telegram feilet: $e');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Telegram lagret!")));
  }"""

changed = 0
if old_email in content:
    content = content.replace(old_email, new_email)
    changed += 1
else:
    print('⚠️  _saveEmail ikke funnet – sjekk manuelt')

if old_tg in content:
    content = content.replace(old_tg, new_tg)
    changed += 1
else:
    print('⚠️  _saveTelegram ikke funnet – sjekk manuelt')

with open('lib/pages/bonusvarsel_alerts_page.dart', 'w') as f:
    f.write(content)
print(f'✅ {changed}/2 funksjoner oppdatert')
PYTHON

echo "✅ E-post og Telegram lagres nå i Firestore"
