#!/bin/bash
set -e
TARGET="lib/pages/bonusvarsel_alerts_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Finner ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_firestore_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

if grep -q "FirebaseFirestore" "$TARGET"; then
  echo "ℹ️  Firestore finnes allerede – hopper over"
  exit 0
fi

# Legg til Firestore-import
sed -i '' "s|import 'package:firebase_auth/firebase_auth.dart';|import 'package:firebase_auth/firebase_auth.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';|" "$TARGET"

python3 - << 'PYTHON'
with open('lib/pages/bonusvarsel_alerts_page.dart', 'r') as f:
    content = f.read()

old = """  Future<void> _syncFavoritesToServer({required List<String> trumf, required List<String> sas}) async {
    debugPrint('SYNC: email=$_emailValue trumf=$trumf');
    try {
      if (!ApiService.hasUsableBaseUrl) return;
      final email = _emailValue.isNotEmpty 
          ? _emailValue 
          : FirebaseAuth.instance.currentUser?.email;
      await ApiService.updateDeviceFavorites(
        trumfFavs: trumf,
        sasFavs: sas,
        email: email,
      );
    } catch (e) {
      debugPrint('Sync favorites feilet: \\$e');
    }
  }"""

new = """  Future<void> _syncFavoritesToServer({required List<String> trumf, required List<String> sas}) async {
    debugPrint('SYNC: email=$_emailValue trumf=$trumf');
    try {
      if (ApiService.hasUsableBaseUrl) {
        final email = _emailValue.isNotEmpty
            ? _emailValue
            : FirebaseAuth.instance.currentUser?.email;
        await ApiService.updateDeviceFavorites(
          trumfFavs: trumf,
          sasFavs: sas,
          email: email,
        );
      }
    } catch (e) {
      debugPrint('Sync Railway feilet: $e');
    }
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'trumfFavs':            trumf,
          'sasFavs':              sas,
          'alertEmail':           _emailValue,
          'alertTelegram':        _telegramValue,
          'notificationsEnabled': _emailValue.isNotEmpty || _telegramValue.isNotEmpty,
          'updatedAt':            FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ Favoritter synket til Firestore');
      }
    } catch (e) {
      debugPrint('Sync Firestore feilet: $e');
    }
  }"""

if old in content:
    content = content.replace(old, new)
    with open('lib/pages/bonusvarsel_alerts_page.dart', 'w') as f:
        f.write(content)
    print('✅ _syncFavoritesToServer oppdatert')
else:
    print('⚠️  Fant ikke eksakt match – sjekk manuelt')
PYTHON

echo "✅ alerts_page oppdatert med Firestore-sync"
