#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_775_create_points_engine_and_recommendation_engine"

mkdir -p lib/models
mkdir -p lib/services

cat > lib/models/bonus_recommendation.dart <<'DART'
enum BonusTier { free, premium, elite }

class PointsBreakdown {
  final double amountNok;
  final int basePoints;
  final int cardPoints;
  final int merchantPoints;
  final int tierBonusPoints;
  final int favoriteBonusPoints;

  const PointsBreakdown({
    required this.amountNok,
    required this.basePoints,
    required this.cardPoints,
    required this.merchantPoints,
    required this.tierBonusPoints,
    required this.favoriteBonusPoints,
  });

  int get totalPoints =>
      basePoints + cardPoints + merchantPoints + tierBonusPoints + favoriteBonusPoints;
}

class RecommendationReason {
  final String title;
  final String detail;

  const RecommendationReason({
    required this.title,
    required this.detail,
  });
}

class BonusRecommendation {
  final String id;
  final String title;
  final String subtitle;
  final int estimatedPoints;
  final int? upliftVsCurrent;
  final bool favorite;
  final BonusTier requiredTier;
  final List<RecommendationReason> reasons;

  const BonusRecommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.estimatedPoints,
    required this.favorite,
    required this.requiredTier,
    required this.reasons,
    this.upliftVsCurrent,
  });
}
DART

cat > lib/services/bonus_points_engine.dart <<'DART'
import '../models/bonus_recommendation.dart';

class BonusPointsEngine {
  static const double _travelBasePer100 = 0.0;

  static int _roundPoints(double value) => value.round();

  static int _favoriteBonus({
    required int subtotalPoints,
    required bool favorite,
    required BonusTier tier,
  }) {
    if (!favorite) return 0;

    switch (tier) {
      case BonusTier.free:
        return 0;
      case BonusTier.premium:
        return _roundPoints(subtotalPoints * 0.03);
      case BonusTier.elite:
        return _roundPoints(subtotalPoints * 0.06);
    }
  }

  static int _tierBonus({
    required int subtotalPoints,
    required BonusTier tier,
  }) {
    switch (tier) {
      case BonusTier.free:
        return 0;
      case BonusTier.premium:
        return _roundPoints(subtotalPoints * 0.05);
      case BonusTier.elite:
        return _roundPoints(subtotalPoints * 0.10);
    }
  }

  static PointsBreakdown estimateTravel({
    required double amountNok,
    required int cardRatePer100,
    BonusTier tier = BonusTier.free,
    bool favorite = false,
  }) {
    if (amountNok <= 0) {
      return const PointsBreakdown(
        amountNok: 0,
        basePoints: 0,
        cardPoints: 0,
        merchantPoints: 0,
        tierBonusPoints: 0,
        favoriteBonusPoints: 0,
      );
    }

    final basePoints = _roundPoints((amountNok / 100.0) * _travelBasePer100);
    final cardPoints = _roundPoints((amountNok / 100.0) * cardRatePer100);

    final subtotal = basePoints + cardPoints;
    final tierBonus = _tierBonus(subtotalPoints: subtotal, tier: tier);
    final favoriteBonus = _favoriteBonus(
      subtotalPoints: subtotal + tierBonus,
      favorite: favorite,
      tier: tier,
    );

    return PointsBreakdown(
      amountNok: amountNok,
      basePoints: basePoints,
      cardPoints: cardPoints,
      merchantPoints: 0,
      tierBonusPoints: tierBonus,
      favoriteBonusPoints: favoriteBonus,
    );
  }

  static PointsBreakdown estimateShopping({
    required double amountNok,
    required double merchantRatePer100,
    required int cardRatePer100,
    BonusTier tier = BonusTier.free,
    bool favorite = false,
  }) {
    if (amountNok <= 0) {
      return const PointsBreakdown(
        amountNok: 0,
        basePoints: 0,
        cardPoints: 0,
        merchantPoints: 0,
        tierBonusPoints: 0,
        favoriteBonusPoints: 0,
      );
    }

    final merchantPoints = _roundPoints((amountNok / 100.0) * merchantRatePer100);
    final cardPoints = _roundPoints((amountNok / 100.0) * cardRatePer100);

    final subtotal = merchantPoints + cardPoints;
    final tierBonus = _tierBonus(subtotalPoints: subtotal, tier: tier);
    final favoriteBonus = _favoriteBonus(
      subtotalPoints: subtotal + tierBonus,
      favorite: favorite,
      tier: tier,
    );

    return PointsBreakdown(
      amountNok: amountNok,
      basePoints: 0,
      cardPoints: cardPoints,
      merchantPoints: merchantPoints,
      tierBonusPoints: tierBonus,
      favoriteBonusPoints: favoriteBonus,
    );
  }
}
DART

cat > lib/services/bonus_recommendation_engine.dart <<'DART'
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
    final rate = _parseRate(item['rate'] ?? item['points'] ?? item['poeng'] ?? item['rateText']);

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

    final total = breakdown.totalPoints;
    final uplift = total - baselinePoints;

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
          detail: 'Favoritt prioriteres høyere i Premium og Elite.',
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
        ? 'Oppgrader for full verdi og prioritering'
        : uplift > 0
            ? 'Ca. +$uplift poeng mot dagens valg'
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
        ? BonusPointsEngine.estimateShopping(
            amountNok: amountNok,
            merchantRatePer100: 0,
            cardRatePer100: cardRate,
            tier: userTier,
            favorite: false,
          ).totalPoints
        : _recommendationFromItem(
                item: currentSelection,
                amountNok: amountNok,
                selectedCardId: selectedCardId,
                userTier: userTier,
                favoriteIds: favoriteIds,
                baselinePoints: 0,
              )
                ?.estimatedPoints ??
            0;

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
      return '${recommendation.title} gir ca. +$uplift poeng mot dagens valg.';
    }
    return '${recommendation.title} er et sterkt valg med ca. ${recommendation.estimatedPoints} poeng.';
  }
}
DART

cat > lib/services/bonus_engine_usage_example.txt <<'TXT'
Eksempel: shopping-anbefaling

import 'package:bonusvarsel/services/bonus_recommendation_engine.dart';

final recommendations = BonusRecommendationEngine.recommendForShopping(
  offers: offersAsMapList,
  amountNok: 5000,
  selectedCardId: selectedCardId,
  tier: isElite ? 'elite' : isPremium ? 'premium' : 'free',
  favoriteIds: favoriteStoreIds,
  currentSelection: currentlySelectedOfferMap,
);

final best = recommendations.isNotEmpty ? recommendations.first : null;


Eksempel: reise-estimat

final travel = BonusRecommendationEngine.recommendForTravel(
  amountNok: 5000,
  selectedCardId: selectedCardId,
  tier: isElite ? 'elite' : isPremium ? 'premium' : 'free',
  favorite: false,
);

print(travel.totalPoints);
TXT

echo "✅ Laget:"
echo " - lib/models/bonus_recommendation.dart"
echo " - lib/services/bonus_points_engine.dart"
echo " - lib/services/bonus_recommendation_engine.dart"
echo " - lib/services/bonus_engine_usage_example.txt"
echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) wire motoren inn i travel_page.dart eller eb_shopping_page.dart"
