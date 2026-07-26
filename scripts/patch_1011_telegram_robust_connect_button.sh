#!/bin/bash
set -euo pipefail

NEW_FILE="lib/services/device_id_service.dart"
API_FILE="lib/services/api_service.dart"
PAGE_FILE="lib/pages/bonusvarsel_alerts_page.dart"
TS="$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$API_FILE" ] || [ ! -f "$PAGE_FILE" ]; then
  echo "❌ Fant ikke forventede filer. Kjør dette scriptet fra rot-mappen i repoet."
  exit 1
fi

if [ -f "$NEW_FILE" ]; then
  echo "❌ $NEW_FILE finnes allerede. Avbryter for å ikke overskrive noe uventet."
  exit 1
fi

cp "$API_FILE" "${API_FILE}.bak_1011_telegram_link_button_${TS}"
cp "$PAGE_FILE" "${PAGE_FILE}.bak_1011_telegram_link_button_${TS}"

cat > "$NEW_FILE" <<'DARTEOF'
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  DeviceIdService._();

  static const _prefsKey = 'bv_device_id';
  static String? _cached;

  static Future<String> getId() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_prefsKey);
    if (id == null || id.isEmpty) {
      id = _generate();
      await prefs.setString(_prefsKey, id);
    }
    _cached = id;
    return id;
  }

  static String _generate() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
DARTEOF

echo "✅ Opprettet $NEW_FILE"

python3 - "$API_FILE" "$PAGE_FILE" <<'PYEOF'
import sys

api_path, page_path = sys.argv[1], sys.argv[2]

with open(api_path, "r", encoding="utf-8") as f:
    api_src = f.read()

old_import = "import '../config/api_config.dart';"
new_import = old_import + "\nimport 'device_id_service.dart';"
if old_import not in api_src:
    print("❌ Fant ikke import-linje i api_service.dart.")
    sys.exit(1)
api_src = api_src.replace(old_import, new_import, 1)

old_method = '''  static Future<void> updateDeviceFavorites({
    required List<String> trumfFavs,
    required List<String> sasFavs,
    String? email,
  }) async {
    final res = await http.post(
      _uri('/v1/devices/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'trumf': trumfFavs, 'sas': sasFavs, 'email': email}),
    ).timeout(const Duration(seconds: 5));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST /v1/devices/favorites failed: \\${res.statusCode}');
    }
  }'''

new_method = '''  static Future<void> updateDeviceFavorites({
    required List<String> trumfFavs,
    required List<String> sasFavs,
    String? email,
    String? telegram,
  }) async {
    final deviceId = await DeviceIdService.getId();
    final res = await http.post(
      _uri('/v1/devices/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'x-device-id': deviceId,
      },
      body: jsonEncode({'trumf': trumfFavs, 'sas': sasFavs, 'email': email, 'telegram': telegram}),
    ).timeout(const Duration(seconds: 5));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST /v1/devices/favorites failed: \\${res.statusCode}');
    }
  }'''

if old_method not in api_src:
    print("❌ Fant ikke updateDeviceFavorites()-blokk i api_service.dart.")
    sys.exit(1)
api_src = api_src.replace(old_method, new_method, 1)

with open(api_path, "w", encoding="utf-8") as f:
    f.write(api_src)
print("✅ api_service.dart oppdatert")

with open(page_path, "r", encoding="utf-8") as f:
    page_src = f.read()

old_import2 = "import '../services/api_service.dart';"
new_import2 = old_import2 + "\nimport '../services/device_id_service.dart';"
if old_import2 not in page_src:
    print("❌ Fant ikke import-linje i bonusvarsel_alerts_page.dart.")
    sys.exit(1)
page_src = page_src.replace(old_import2, new_import2, 1)

old_sync_call = '''        await ApiService.updateDeviceFavorites(
          trumfFavs: trumf,
          sasFavs: sas,
          email: email,
        );'''
new_sync_call = '''        await ApiService.updateDeviceFavorites(
          trumfFavs: trumf,
          sasFavs: sas,
          email: email,
          telegram: _telegramValue.isNotEmpty ? _telegramValue : null,
        );'''
if old_sync_call not in page_src:
    print("❌ Fant ikke updateDeviceFavorites()-kall i bonusvarsel_alerts_page.dart.")
    sys.exit(1)
page_src = page_src.replace(old_sync_call, new_sync_call, 1)

old_save_telegram = '''  Future<void> _saveTelegram() async {
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
  }'''

new_save_telegram = '''  Future<void> _saveTelegram() async {
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
    await _syncFavoritesToServer(trumf: _trumfFavIds, sas: _sasFavIds);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Telegram lagret!")));
  }

  Future<void> _connectTelegramViaLink() async {
    final deviceId = await DeviceIdService.getId();
    final uri = Uri.parse("https://t.me/bonusvarsel_varsel_bot?start=$deviceId");
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Klarte ikke å åpne Telegram. Er appen installert?")),
      );
    }
  }'''

if old_save_telegram not in page_src:
    print("❌ Fant ikke _saveTelegram()-blokk.")
    sys.exit(1)
page_src = page_src.replace(old_save_telegram, new_save_telegram, 1)

old_button = '''            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse("https://t.me/BonusvarselBot")),
              child: const Text("Åpne Bot"),
            ),'''
new_button = '''            ElevatedButton(
              onPressed: _connectTelegramViaLink,
              child: const Text("Koble til Telegram"),
            ),'''
if old_button not in page_src:
    print("❌ Fant ikke 'Åpne Bot'-knappen.")
    sys.exit(1)
page_src = page_src.replace(old_button, new_button, 1)

with open(page_path, "w", encoding="utf-8") as f:
    f.write(page_src)
print("✅ bonusvarsel_alerts_page.dart oppdatert")
PYEOF

echo
echo "Verifiser:"
echo "  flutter analyze"
