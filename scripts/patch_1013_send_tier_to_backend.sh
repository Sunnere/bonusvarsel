#!/bin/bash
set -euo pipefail

API_FILE="lib/services/api_service.dart"
PAGE_FILE="lib/pages/bonusvarsel_alerts_page.dart"
TS="$(date +%Y%m%d_%H%M%S)"

cp "$API_FILE" "${API_FILE}.bak_1013_tier_sync_${TS}"
cp "$PAGE_FILE" "${PAGE_FILE}.bak_1013_tier_sync_${TS}"

python3 - "$API_FILE" "$PAGE_FILE" <<'PYEOF'
import sys

api_path, page_path = sys.argv[1], sys.argv[2]

with open(api_path, "r", encoding="utf-8") as f:
    api_src = f.read()

old_method = '''  static Future<void> updateDeviceFavorites({
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

new_method = '''  static Future<void> updateDeviceFavorites({
    required List<String> trumfFavs,
    required List<String> sasFavs,
    String? email,
    String? telegram,
    String tier = 'free',
  }) async {
    final deviceId = await DeviceIdService.getId();
    final res = await http.post(
      _uri('/v1/devices/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'x-device-id': deviceId,
      },
      body: jsonEncode({'trumf': trumfFavs, 'sas': sasFavs, 'email': email, 'telegram': telegram, 'tier': tier}),
    ).timeout(const Duration(seconds: 5));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST /v1/devices/favorites failed: \\${res.statusCode}');
    }
  }'''

if old_method not in api_src:
    print("❌ Fant ikke blokk i api_service.dart.")
    sys.exit(1)
api_src = api_src.replace(old_method, new_method, 1)
with open(api_path, "w", encoding="utf-8") as f:
    f.write(api_src)
print("✅ api_service.dart oppdatert")

with open(page_path, "r", encoding="utf-8") as f:
    page_src = f.read()

old_call = '''        await ApiService.updateDeviceFavorites(
          trumfFavs: trumf,
          sasFavs: sas,
          email: email,
          telegram: _telegramValue.isNotEmpty ? _telegramValue : null,
        );'''
new_call = '''        await ApiService.updateDeviceFavorites(
          trumfFavs: trumf,
          sasFavs: sas,
          email: email,
          telegram: _telegramValue.isNotEmpty ? _telegramValue : null,
          tier: EntitlementService.instance.plan,
        );'''
if old_call not in page_src:
    print("❌ Fant ikke kall i bonusvarsel_alerts_page.dart.")
    sys.exit(1)
page_src = page_src.replace(old_call, new_call, 1)
with open(page_path, "w", encoding="utf-8") as f:
    f.write(page_src)
print("✅ bonusvarsel_alerts_page.dart oppdatert")
PYEOF

echo "Verifiser: flutter analyze"
