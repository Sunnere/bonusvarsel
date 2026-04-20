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
