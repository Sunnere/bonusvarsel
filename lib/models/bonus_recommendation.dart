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
