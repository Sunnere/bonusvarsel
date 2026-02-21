#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/eb_repository.dart"
mkdir -p "$(dirname "$FILE")"
[ -f "$FILE" ] && cp "$FILE" "$FILE.bak.$(date +%s)" || true

cat > "$FILE" <<'DART'
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class EbRepository {
  static const _cacheKey = 'eb_shop_cache_json';
  static const _cacheTsKey = 'eb_shop_cache_ts';
  static const _cacheTtlMs = 12 * 60 * 60 * 1000; // 12 timer

  static Future<String?> _loadRawFromAssets() async {
    const candidates = <String>[
      'assets/eb.shopping.pretty.json',
      'assets/eb.shopping.min.json',
      'assets/eb.shopping.json',
      'assets/data/eb.shopping.pretty.json',
      'assets/data/eb.shopping.min.json',
      'assets/data/eb.shopping.json',
    ];

    for (final p in candidates) {
      try {
        return await rootBundle.loadString(p);
      } catch (_) {}
    }
    return null;
  }

  static Map<String, dynamic> _normShop(Map raw) {
    final m = Map<String, dynamic>.from(raw);

    final name = (m['name'] ?? m['shop'] ?? '').toString().trim();
    final rateRaw = m['rate'] ?? m['points'] ?? m['poeng'];
    final rateNum = (rateRaw is num)
        ? rateRaw.toDouble()
        : double.tryParse(rateRaw?.toString() ?? '') ?? 0.0;

    final url = (m['url'] ?? m['link'] ?? '').toString().trim();
    final category = (m['category'] ?? m['cat'] ?? 'Alle').toString().trim();
    final isCampaignRaw = m['isCampaign'] ?? m['campaign'] ?? m['is_campaign'];
    final isCampaign = (isCampaignRaw is bool)
        ? isCampaignRaw
        : (isCampaignRaw?.toString().toLowerCase() == 'true');

    return <String, dynamic>{
      'name': name,
      'rate': rateNum,
      'url': url,
      'category': category.isEmpty ? 'Alle' : category,
      'isCampaign': isCampaign,
    };
  }

  static List<Map<String, dynamic>> _decodeToList(String jsonStr) {
    final decoded = json.decode(jsonStr);
    final List<dynamic> rawList;
    if (decoded is Map && decoded['shops'] is List) {
      rawList = (decoded['shops'] as List).cast<dynamic>();
    } else if (decoded is List) {
      rawList = decoded.cast<dynamic>();
    } else {
      rawList = const <dynamic>[];
    }

    final out = <Map<String, dynamic>>[];
    for (final it in rawList) {
      if (it is! Map) continue;
      final s = _normShop(it);
      if ((s['name'] as String).isEmpty) continue;
      out.add(s);
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> loadShops({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final ts = prefs.getInt(_cacheTsKey) ?? 0;
      final cached = prefs.getString(_cacheKey);
      final fresh = (DateTime.now().millisecondsSinceEpoch - ts) < _cacheTtlMs;
      if (cached != null && cached.isNotEmpty && fresh) {
        try {
          return _decodeToList(cached);
        } catch (_) {}
      }
    }

    final raw = await _loadRawFromAssets();
    if (raw == null) return <Map<String, dynamic>>[];

    // cache
    await prefs.setString(_cacheKey, raw);
    await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);

    return _decodeToList(raw);
  }
}
DART

dart format "$FILE" >/dev/null
echo "✅ Skrev + formaterte: $FILE"
