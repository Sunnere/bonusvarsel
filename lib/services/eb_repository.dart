import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_offer.dart';

class EbRepository {
  // Cache keys
  static const _cacheKey = 'eb_shop_cache_v1';
  static const _cacheTsKey = 'eb_shop_cache_ts_v1';

  // 6 timer er en fin start (kan justeres)
  static const Duration cacheTtl = Duration(hours: 6);

  // Kandidatfiler (i prioritert rekkefølge)
  static const List<String> _assetCandidates = <String>[
    'assets/eb.shopping.pretty.json',
    'assets/eb.shopping.min.json',
    'assets/eb.shopping.json',
    'assets/shops.json',
    'assets/offers.json',
    'assets/offers.min.json',
    'assets/data/offers.json',
    'assets/data/offers.min.json',
  ];

  Future<List<ShopOffer>> fetchShops({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = _readCache(prefs);
      if (cached != null) return cached;
    }

    final raw = await _loadRawFromAssets();
    final shops = _normalize(raw);

    // Cache resultat
    await prefs.setString(
        _cacheKey, jsonEncode(shops.map((s) => s.toJson()).toList()));
    await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);

    return shops;
  }

  List<ShopOffer>? _readCache(SharedPreferences prefs) {
    final ts = prefs.getInt(_cacheTsKey);
    final s = prefs.getString(_cacheKey);

    if (ts == null || s == null || s.isEmpty) return null;

    final age =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age > cacheTtl) return null;

    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return null;
      final out = <ShopOffer>[];
      for (final it in decoded) {
        final shop = ShopOffer.fromAny(it);
        if (shop != null) out.add(shop);
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _loadRawFromAssets() async {
    String? jsonStr;

    for (final p in _assetCandidates) {
      try {
        jsonStr = await rootBundle.loadString(p);
        if (jsonStr.trim().isNotEmpty) {
          // Fant en fil som finnes og har innhold
          break;
        }
      } catch (_) {
        // ignore - prøv neste
      }
    }

    if (jsonStr == null || jsonStr.trim().isEmpty) {
      // Tomt -> tom liste
      return const <dynamic>[];
    }

    return jsonDecode(jsonStr);
  }

  List<ShopOffer> _normalize(dynamic decoded) {
    // Godtar både:
    // 1) { "shops": [ ... ] }
    // 2) [ ... ]
    List<dynamic> rawList;

    if (decoded is Map && decoded['shops'] is List) {
      rawList = List<dynamic>.from(decoded['shops'] as List);
    } else if (decoded is List) {
      rawList = List<dynamic>.from(decoded);
    } else {
      rawList = const <dynamic>[];
    }

    final out = <ShopOffer>[];
    final seen = <String>{};

    for (final it in rawList) {
      final shop = ShopOffer.fromAny(it);
      if (shop == null) continue;

      // dedupe på name + url
      final key = '${shop.name}||${shop.url}';
      if (seen.contains(key)) continue;
      seen.add(key);

      out.add(shop);
    }

    // Stabil sort: høy rate først, ellers alfabetisk
    out.sort((a, b) {
      final r = b.rate.compareTo(a.rate);
      if (r != 0) return r;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return out;
  }
}
