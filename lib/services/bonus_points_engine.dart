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
