import 'eb_shopping_offer_vm.dart';

class EbShoppingOffersAdapter {
  const EbShoppingOffersAdapter();

  EbShoppingOfferVm? fromFeedItem(dynamic item) {
    if (item == null) return null;

    final map = _asMap(item);
    if (map == null) return null;

    final id = _str(map, ['id', 'offerId', 'uuid']);
    final title = _str(map, ['title', 'name', 'headline']);

    if (id == null || id.isEmpty) return null;
    if (title == null || title.isEmpty) return null;

    final expiresAtRaw = _first(map, ['expiresAt', 'expiryDate', 'validTo']);
    DateTime? expiresAt;
    if (expiresAtRaw is String && expiresAtRaw.trim().isNotEmpty) {
      expiresAt = DateTime.tryParse(expiresAtRaw);
    }

    final category = (_str(map, [
          'category',
          'vertical',
          'placement',
          'type'
        ]) ??
        'eb_shopping')
        .trim();

    return EbShoppingOfferVm(
      id: id,
      title: title,
      subtitle: _str(map, ['subtitle', 'subTitle', 'tagline']),
      description: _str(map, ['description', 'body', 'details']),
      imageUrl: _str(map, ['imageUrl', 'image', 'thumbnailUrl']),
      merchantName: _str(map, ['merchantName', 'merchant', 'brand']),
      pointsText: _str(map, ['pointsText', 'rewardText', 'bonusText']),
      ctaText: _str(map, ['ctaText', 'ctaLabel', 'buttonText']),
      deeplink: _str(map, ['deeplink', 'url', 'targetUrl', 'trackingUrl']),
      category: category,
      featured: _bool(map, ['featured', 'isFeatured']) ?? false,
      sponsored: _bool(map, ['sponsored', 'isSponsored', 'ad']) ?? false,
      priority: _int(map, ['priority', 'rank', 'score']) ?? 0,
      expiresAt: expiresAt,
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic>? _asMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    try {
      final dynamic json = item.toJson();
      if (json is Map<String, dynamic>) {
        return json;
      }
    } catch (_) {}
    return null;
  }

  dynamic _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return map[key];
    }
    return null;
  }

  String? _str(Map<String, dynamic> map, List<String> keys) {
    final value = _first(map, keys);
    if (value == null) return null;
    return value.toString().trim();
  }

  bool? _bool(Map<String, dynamic> map, List<String> keys) {
    final value = _first(map, keys);
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  int? _int(Map<String, dynamic> map, List<String> keys) {
    final value = _first(map, keys);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
