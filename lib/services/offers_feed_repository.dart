import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/offer_feed_item.dart';
import '../models/offers_feed_response.dart';
import 'api_service.dart';

class OffersFeedRepository {
  static const String _cacheKey = 'offers_feed.cache.v1';
  static const String _cacheTsKey = 'offers_feed.cache_ts.v1';
  static const Duration maxCacheAge = Duration(hours: 6);

  const OffersFeedRepository();

  Future<OffersFeedResponse> fetchOffers({
    String? program,
    String? level,
    String? category,
    String? updatedSince,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = _readCache(prefs);
      if (cached != null) return cached;
    }

    try {
      final raw = await ApiService.getOffersFeed(
        program: program,
        level: level,
        category: category,
        updatedSince: updatedSince,
      );
      final response = OffersFeedResponse.fromJson(raw);
      await _writeCache(prefs, response);
      return response;
    } catch (_) {
      final fallback = _readStaleCache(prefs);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  Future<List<OfferFeedItem>> fetchActiveItems({
    String? program,
    String? level,
    String? category,
    bool forceRefresh = false,
  }) async {
    final feed = await fetchOffers(
      program: program,
      level: level,
      category: category,
      forceRefresh: forceRefresh,
    );

    return feed.items.where((e) => e.isActive && !e.isExpired).toList();
  }

  OffersFeedResponse? _readCache(SharedPreferences prefs) {
    final ts = prefs.getInt(_cacheTsKey);
    final raw = prefs.getString(_cacheKey);
    if (ts == null || raw == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > maxCacheAge.inMilliseconds) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return OffersFeedResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  OffersFeedResponse? _readStaleCache(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return OffersFeedResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    SharedPreferences prefs,
    OffersFeedResponse response,
  ) async {
    final payload = {
      'items': response.items.map((e) => e.toJson()).toList(),
      'nextCursor': response.nextCursor,
      'serverTime': response.serverTime,
      'version': response.version,
    };

    await prefs.setString(_cacheKey, jsonEncode(payload));
    await prefs.setInt(
      _cacheTsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
