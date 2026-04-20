import 'eb_shopping_offer_vm.dart';
import 'eb_shopping_offers_adapter.dart';

class EbShoppingOffersDataSource {
  final dynamic offersFeedRepository;
  final EbShoppingOffersAdapter adapter;
  final Future<List<EbShoppingOfferVm>> Function()? legacyFallbackLoader;

  const EbShoppingOffersDataSource({
    required this.offersFeedRepository,
    this.adapter = const EbShoppingOffersAdapter(),
    this.legacyFallbackLoader,
  });

  Future<List<EbShoppingOfferVm>> load({
    bool allowFallback = true,
    int limit = 50,
  }) async {
    try {
      final response = await offersFeedRepository.fetchOffersFeed();
      final items = _extractItems(response);

      final mapped = items
          .map(adapter.fromFeedItem)
          .whereType<EbShoppingOfferVm>()
          .where(_isRelevantForEbShopping)
          .where((e) => !e.isExpired)
          .toList()
        ..sort((a, b) {
          final featuredCompare =
              (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
          if (featuredCompare != 0) return featuredCompare;
          return b.priority.compareTo(a.priority);
        });

      if (mapped.isNotEmpty) {
        return mapped.take(limit).toList();
      }
    } catch (_) {
      // Silent fallback by design in this migration phase.
    }

    if (allowFallback && legacyFallbackLoader != null) {
      return legacyFallbackLoader!.call();
    }

    return <EbShoppingOfferVm>[];
  }

  List<dynamic> _extractItems(dynamic response) {
    if (response == null) return <dynamic>[];

    try {
      final dynamic items = response.items;
      if (items is List) return items;
    } catch (_) {}

    try {
      final dynamic offers = response.offers;
      if (offers is List) return offers;
    } catch (_) {}

    try {
      final dynamic json = response.toJson();
      if (json is Map<String, dynamic>) {
        final items = json['items'];
        if (items is List) return items;

        final offers = json['offers'];
        if (offers is List) return offers;
      }
    } catch (_) {}

    return <dynamic>[];
  }

  bool _isRelevantForEbShopping(EbShoppingOfferVm offer) {
    final haystack = [
      offer.category,
      offer.title,
      offer.subtitle,
      offer.description,
      offer.merchantName,
      offer.pointsText,
      offer.raw['channel']?.toString(),
      offer.raw['surface']?.toString(),
      offer.raw['placement']?.toString(),
      offer.raw['program']?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains('eb shopping') ||
        haystack.contains('eurobonus shopping') ||
        haystack.contains('shopping portal') ||
        haystack.contains('online shopping') ||
        haystack.contains('sas shopping') ||
        offer.category.toLowerCase().contains('shopping');
  }
}
