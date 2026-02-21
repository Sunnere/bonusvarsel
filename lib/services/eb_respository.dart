import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class EbRepository {
  static const _cacheKey = 'eb_shops_cache_v1';
  static const _cacheTsKey = 'eb_shops_cache_ts_v1';

  // TTL: 6 timer
  static const cacheTtlMs = 6 * 60 * 60 * 1000;

  Future<Map<String, dynamic>> loadRaw() async {
    // 1) prøv cache
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheTsKey);
    final cached = prefs.getString(_cacheKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cached != null && ts != null && (now - ts) < cacheTtlMs) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }

    // 2) fallback til asset
    final text = await rootBundle.loadString('assets/eb.shopping.min.json');
    final data = jsonDecode(text) as Map<String, dynamic>;

    // 3) lagre i cache
    await prefs.setString(_cacheKey, jsonEncode(data));
    await prefs.setInt(_cacheTsKey, now);

    return data;
  }

  Future<List<dynamic>> loadShops() async {
    final raw = await loadRaw();
    final shops = raw['shops'];
    if (shops is List) return shops;
    return const [];
  }

  Future<List<dynamic>> loadCampaigns() async {
    final raw = await loadRaw();
    final campaigns = raw['campaigns'];
    if (campaigns is List) return campaigns;
    return const [];
  }

  Future<void> forceRefreshFromAsset() async {
    final prefs = await SharedPreferences.getInstance();
    final text = await rootBundle.loadString('assets/eb.shopping.min.json');
    await prefs.setString(_cacheKey, text);
    await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);
  }
}
