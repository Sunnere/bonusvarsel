#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_804_create_missing_offers_feed_foundation"

mkdir -p lib/models
mkdir -p lib/services

API_FILE="lib/services/api_service.dart"

if [ ! -f "$API_FILE" ]; then
  echo "❌ Fant ikke $API_FILE"
  exit 1
fi

cp "$API_FILE" "$API_FILE.bak_804_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

cat > lib/models/offer_feed_item.dart <<'DART'
class OfferFeedItem {
  final String id;
  final String program;
  final String programLabel;
  final String storeId;
  final String storeName;
  final String category;
  final String subcategory;
  final double rate;
  final String rateText;
  final String currency;
  final String level;
  final String source;
  final String campaign;
  final List<String> tags;
  final String url;
  final String validFrom;
  final String validTo;
  final String updatedAt;
  final String lastSeenAt;
  final bool isActive;
  final bool isExpired;
  final double confidence;

  const OfferFeedItem({
    required this.id,
    required this.program,
    required this.programLabel,
    required this.storeId,
    required this.storeName,
    required this.category,
    required this.subcategory,
    required this.rate,
    required this.rateText,
    required this.currency,
    required this.level,
    required this.source,
    required this.campaign,
    required this.tags,
    required this.url,
    required this.validFrom,
    required this.validTo,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.isActive,
    required this.isExpired,
    required this.confidence,
  });

  factory OfferFeedItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return OfferFeedItem(
      id: (json['id'] ?? '').toString(),
      program: (json['program'] ?? 'other').toString(),
      programLabel: (json['programLabel'] ?? '').toString(),
      storeId: (json['storeId'] ?? '').toString(),
      storeName: (json['storeName'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      subcategory: (json['subcategory'] ?? '').toString(),
      rate: parseDouble(json['rate']),
      rateText: (json['rateText'] ?? '').toString(),
      currency: (json['currency'] ?? 'NOK').toString(),
      level: (json['level'] ?? 'free').toString(),
      source: (json['source'] ?? '').toString(),
      campaign: (json['campaign'] ?? '').toString(),
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      url: (json['url'] ?? '').toString(),
      validFrom: (json['validFrom'] ?? '').toString(),
      validTo: (json['validTo'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      lastSeenAt: (json['lastSeenAt'] ?? '').toString(),
      isActive: json['isActive'] == true,
      isExpired: json['isExpired'] == true,
      confidence: parseDouble(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'program': program,
      'programLabel': programLabel,
      'storeId': storeId,
      'storeName': storeName,
      'category': category,
      'subcategory': subcategory,
      'rate': rate,
      'rateText': rateText,
      'currency': currency,
      'level': level,
      'source': source,
      'campaign': campaign,
      'tags': tags,
      'url': url,
      'validFrom': validFrom,
      'validTo': validTo,
      'updatedAt': updatedAt,
      'lastSeenAt': lastSeenAt,
      'isActive': isActive,
      'isExpired': isExpired,
      'confidence': confidence,
    };
  }
}
DART

cat > lib/models/offers_feed_response.dart <<'DART'
import 'offer_feed_item.dart';

class OffersFeedResponse {
  final List<OfferFeedItem> items;
  final String? nextCursor;
  final String serverTime;
  final int version;

  const OffersFeedResponse({
    required this.items,
    required this.nextCursor,
    required this.serverTime,
    required this.version,
  });

  factory OffersFeedResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return OffersFeedResponse(
      items: rawItems
          .whereType<Map>()
          .map((e) => OfferFeedItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      nextCursor: json['nextCursor']?.toString(),
      serverTime: (json['serverTime'] ?? '').toString(),
      version: (json['version'] is num) ? (json['version'] as num).toInt() : 1,
    );
  }
}
DART

cat > lib/services/offers_feed_repository.dart <<'DART'
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
      final response = await ApiService.getOffersFeed(
        program: program,
        level: level,
        category: category,
        updatedSince: updatedSince,
      );
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
DART

cat > lib/services/offers_refresh_service.dart <<'DART'
import '../models/offer_feed_item.dart';
import 'offers_feed_repository.dart';

class OffersRefreshService {
  final OffersFeedRepository repo;

  const OffersRefreshService({
    this.repo = const OffersFeedRepository(),
  });

  Future<List<OfferFeedItem>> refreshForProgram(
    String program, {
    String? level,
    bool forceRefresh = true,
  }) {
    return repo.fetchActiveItems(
      program: program,
      level: level,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<OfferFeedItem>> refreshAll({
    String? level,
    bool forceRefresh = true,
  }) {
    return repo.fetchActiveItems(
      level: level,
      forceRefresh: forceRefresh,
    );
  }
}
DART

python3 <<'PY'
from pathlib import Path

path = Path("lib/services/api_service.dart")
text = path.read_text()

if "static Future<Map<String, dynamic>> getOffersFeed({" in text:
    print("ℹ️ ApiService.getOffersFeed(...) finnes allerede")
else:
    insertion = """

  static Future<Map<String, dynamic>> getOffersFeed({
    String? program,
    String? level,
    String? category,
    String? updatedSince,
  }) async {
    final query = <String, String>{};

    if (program != null && program.isNotEmpty) query['program'] = program;
    if (level != null && level.isNotEmpty) query['level'] = level;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (updatedSince != null && updatedSince.isNotEmpty) {
      query['updated_since'] = updatedSince;
    }

    final uri = _uri('/v1/offers').replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 4));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET /v1/offers failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('GET /v1/offers expected JSON object');
    }

    return decoded;
  }
"""
    marker = "  static Future<List<OfferRecord>> getOffers() async {"
    if marker not in text:
      raise SystemExit("❌ Fant ikke innsettingspunkt i api_service.dart")
    text = text.replace(marker, insertion + "\n" + marker, 1)
    path.write_text(text)
    print("✅ La til ApiService.getOffersFeed(...)")
PY

cat > lib/services/offers_feed_usage_example.txt <<'TXT'
Eksempel:

final repo = OffersFeedRepository();
final items = await repo.fetchActiveItems(
  program: 'sas',
  level: 'premium',
);

Appen bør etter hvert lese offers fra denne feeden i stedet for bare eldre/mockede kilder.
TXT

echo
echo "==> Verifisering"
ls -la lib/models/offer_feed_item.dart
ls -la lib/models/offers_feed_response.dart
ls -la lib/services/offers_feed_repository.dart
ls -la lib/services/offers_refresh_service.dart
grep -n "getOffersFeed" lib/services/api_service.dart || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) hvis grønt nok: bruk disse filene videre"
