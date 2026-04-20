import '../models/bonus_recommendation.dart';
import '../models/card_catalog.dart';
import 'bonus_points_engine.dart';

class BonusRecommendationEngine {
  static BonusTier tierFromString(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'elite':
        return BonusTier.elite;
      case 'premium':
        return BonusTier.premium;
      default:
        return BonusTier.free;
    }
  }

  static double _parseRate(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();

    final text = raw.toString().trim().toLowerCase();
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(text);
    if (match == null) return 0.0;

    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
  }

  static String _storeName(Map<String, dynamic> item) {
    return (item['store'] ??
            item['name'] ??
            item['merchant'] ??
            item['title'] ??
            'Ukjent butikk')
        .toString();
  }

  static String _itemId(Map<String, dynamic> item) {
    return (item['id'] ??
            item['storeId'] ??
            item['slug'] ??
            item['store'] ??
            item['name'] ??
            'unknown')
        .toString();
  }

  static String _category(Map<String, dynamic> item) {
    return (item['category'] ?? item['type'] ?? 'shopping').toString();
  }

  static BonusTier _requiredTier(Map<String, dynamic> item) {
    final level = (item['level'] ?? item['plan'] ?? '').toString().toLowerCase();
    if (level.contains('elite')) return BonusTier.elite;
    if (level.contains('premium')) return BonusTier.premium;
    return BonusTier.free;
  }

  static bool _isFavorite({
    required Map<String, dynamic> item,
    required Set<String> favoriteIds,
  }) {
    final id = _itemId(item);
    final store = _storeName(item).toLowerCase();
    return favoriteIds.contains(id) ||
        favoriteIds.contains(store) ||
        favoriteIds.contains(id.toLowerCase());
  }

  static bool _tierAllows(BonusTier userTier, BonusTier requiredTier) {
    const rank = {
      BonusTier.free: 0,
      BonusTier.premium: 1,
      BonusTier.elite: 2,
    };
    return rank[userTier]! >= rank[requiredTier]!;
  }

  static int _capEstimatedPoints(int value) {
    if (value < 0) return 0;
    if (value > 5000) return 5000;
    return value;
  }

  static int _capUplift(int value) {
    if (value < 0) return 0;
    if (value > 1200) return 1200;
    return value;
  }

  static int _baselinePoints({
    required double amountNok,
    required int cardRate,
    required BonusTier tier,
  }) {
    final baseline = BonusPointsEngine.estimateShopping(
      amountNok: amountNok,
      merchantRatePer100: 0.0,
      cardRatePer100: cardRate,
      tier: tier,
      favorite: false,
    ).totalPoints;

    return _capEstimatedPoints(baseline);
  }

  static BonusRecommendation? _recommendationFromItem({
    required Map<String, dynamic> item,
    required double amountNok,
    required String? selectedCardId,
    required BonusTier userTier,
    required Set<String> favoriteIds,
    required int baselinePoints,
  }) {
    final category = _category(item).toLowerCase();
    final requiredTier = _requiredTier(item);
    final available = _tierAllows(userTier, requiredTier);
    final favorite = _isFavorite(item: item, favoriteIds: favoriteIds);
    final cardRate = CardCatalog.rateFor(selectedCardId);

    final rawRate =
        _parseRate(item['rate'] ?? item['points'] ?? item['poeng'] ?? item['rateText']);

    // Stram inn rate så tallene ikke blåser opp.
    final rate = rawRate > 40 ? 40.0 : rawRate;

    final breakdown = category.contains('travel')
        ? BonusPointsEngine.estimateTravel(
            amountNok: amountNok,
            cardRatePer100: cardRate,
            tier: userTier,
            favorite: favorite,
          )
        : BonusPointsEngine.estimateShopping(
            amountNok: amountNok,
            merchantRatePer100: rate,
            cardRatePer100: cardRate,
            tier: userTier,
            favorite: favorite,
          );

    final total = _capEstimatedPoints(breakdown.totalPoints);
    final uplift = _capUplift(total - baselinePoints);

    final reasons = <RecommendationReason>[
      RecommendationReason(
        title: 'Estimert poengsum',
        detail: '$total poeng for ca. ${amountNok.toStringAsFixed(0)} kr',
      ),
      if (rate > 0)
        RecommendationReason(
          title: 'Butikkrate',
          detail: '${rate.toStringAsFixed(2)} poeng per 100 kr',
        ),
      if (cardRate > 0)
        RecommendationReason(
          title: 'Valgt kort',
          detail: '$cardRate poeng per 100 kr',
        ),
      if (favorite)
        const RecommendationReason(
          title: 'Favoritt',
          detail: 'Favoritter prioriteres høyere når appen finner gode valg.',
        ),
      if (!available)
        RecommendationReason(
          title: 'Krever oppgradering',
          detail: requiredTier == BonusTier.elite
              ? 'Denne anbefalingen er låst til Elite.'
              : 'Denne anbefalingen er låst til Premium.',
        ),
    ];

    final store = _storeName(item);
    final subtitle = !available
        ? 'Oppgrader for å se full verdi'
        : uplift > 0
            ? 'Ca. +$uplift poeng mot standardvalg'
            : 'Sterkt valg for denne handelen';

    return BonusRecommendation(
      id: _itemId(item),
      title: store,
      subtitle: subtitle,
      estimatedPoints: total,
      upliftVsCurrent: uplift,
      favorite: favorite,
      requiredTier: requiredTier,
      reasons: reasons,
    );
  }

  static List<BonusRecommendation> recommendForShopping({
    required List<Map<String, dynamic>> offers,
    required double amountNok,
    String? selectedCardId,
    String tier = 'free',
    Set<String> favoriteIds = const {},
    Map<String, dynamic>? currentSelection,
  }) {
    final userTier = tierFromString(tier);
    final cardRate = CardCatalog.rateFor(selectedCardId);

    final baseline = currentSelection == null
        ? _baselinePoints(
            amountNok: amountNok,
            cardRate: cardRate,
            tier: userTier,
          )
        : (_recommendationFromItem(
                  item: currentSelection,
                  amountNok: amountNok,
                  selectedCardId: selectedCardId,
                  userTier: userTier,
                  favoriteIds: favoriteIds,
                  baselinePoints: 0,
                )
                ?.estimatedPoints ??
            _baselinePoints(
              amountNok: amountNok,
              cardRate: cardRate,
              tier: userTier,
            ));

    final recommendations = offers
        .map(
          (item) => _recommendationFromItem(
            item: item,
            amountNok: amountNok,
            selectedCardId: selectedCardId,
            userTier: userTier,
            favoriteIds: favoriteIds,
            baselinePoints: baseline,
          ),
        )
        .whereType<BonusRecommendation>()
        .toList();

    recommendations.sort((a, b) {
      final favCmp = (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
      if (favCmp != 0) return favCmp;

      final pointsCmp = b.estimatedPoints.compareTo(a.estimatedPoints);
      if (pointsCmp != 0) return pointsCmp;

      return a.title.compareTo(b.title);
    });

    return recommendations;
  }

  static PointsBreakdown recommendForTravel({
    required double amountNok,
    required String? selectedCardId,
    String tier = 'free',
    bool favorite = false,
  }) {
    final userTier = tierFromString(tier);
    final cardRate = CardCatalog.rateFor(selectedCardId);

    return BonusPointsEngine.estimateTravel(
      amountNok: amountNok,
      cardRatePer100: cardRate,
      tier: userTier,
      favorite: favorite,
    );
  }

  static String recommendationSummary({
    required BonusRecommendation recommendation,
  }) {
    final uplift = recommendation.upliftVsCurrent ?? 0;
    if (uplift > 0) {
      return '${recommendation.title} kan gi deg ca. +$uplift poeng mer enn standardvalget.';
    }
    return '${recommendation.title} er et sterkt valg med ca. ${recommendation.estimatedPoints} poeng.';
  }
}
