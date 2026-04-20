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
