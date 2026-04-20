import 'package:flutter/material.dart';

import '../models/bonus_recommendation.dart';
import '../models/shop_offer.dart';
import '../models/subscription_tier.dart';
import '../services/bonus_recommendation_engine.dart';
import '../services/subscription_service.dart';
import '../services/user_state.dart';

class SmartBestRecommendationCard extends StatelessWidget {
  final Future<List<ShopOffer>> futureOffers;
  final double amountNok;
  final VoidCallback? onTapPaywall;

  const SmartBestRecommendationCard({
    super.key,
    required this.futureOffers,
    required this.amountNok,
    this.onTapPaywall,
  });

  static const double _nokPerPoint = 0.10;

  Future<_RecommendationState> _loadState() async {
    final selectedCardId = await UserState.getSelectedCardId();
    final tierEnum = await SubscriptionService.instance.getTier();

    final tier = switch (tierEnum) {
      SubscriptionTier.elite => 'elite',
      SubscriptionTier.pro => 'premium',
      SubscriptionTier.free => 'free',
    };

    return _RecommendationState(
      selectedCardId: selectedCardId,
      tier: tier,
    );
  }

  static int _pointsToNok(int points) {
    if (points <= 0) return 0;
    return (points * _nokPerPoint).round();
  }

  static int _tierRank(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
        return 2;
      case 'premium':
        return 1;
      default:
        return 0;
    }
  }

  static String _tierLabel(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
        return 'Elite';
      case 'premium':
        return 'Premium';
      default:
        return 'Gratis';
    }
  }

  static String _requiredTierLabel(BonusTier tier) {
    switch (tier) {
      case BonusTier.elite:
        return 'Elite';
      case BonusTier.premium:
        return 'Premium';
      case BonusTier.free:
        return 'Gratis';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RecommendationState>(
      future: _loadState(),
      builder: (context, stateSnap) {
        final state = stateSnap.data ??
            const _RecommendationState(
              selectedCardId: null,
              tier: 'free',
            );

        return FutureBuilder<List<ShopOffer>>(
          future: futureOffers,
          builder: (context, offersSnap) {
            final offers = offersSnap.data ?? const <ShopOffer>[];
            if (offers.isEmpty) {
              return const SizedBox.shrink();
            }

            final offerMaps = offers.map((s) => s.toJson()).toList();

            final recommendations = BonusRecommendationEngine.recommendForShopping(
              offers: offerMaps,
              amountNok: amountNok,
              selectedCardId: state.selectedCardId,
              tier: state.tier,
              favoriteIds: const <String>{},
            );

            if (recommendations.isEmpty) {
              return const SizedBox.shrink();
            }

            final best = recommendations.first;
            final safePoints = best.estimatedPoints > 5000 ? 5000 : best.estimatedPoints;

            final rawUplift = best.upliftVsCurrent ?? 0;
            final uplift = rawUplift <= 0 ? 0 : (rawUplift > 1200 ? 1200 : rawUplift);

            final estimatedNok = _pointsToNok(safePoints);
            final upliftNok = _pointsToNok(uplift);

            final currentRank = _tierRank(state.tier);
            final requiredRank = switch (best.requiredTier) {
              BonusTier.free => 0,
              BonusTier.premium => 1,
              BonusTier.elite => 2,
            };

            final locked = requiredRank > currentRank;
            final upgradeLabel = _requiredTierLabel(best.requiredTier);

            final titleText = locked
                ? '🔒 Du går glipp av dette'
                : state.tier == 'elite'
                    ? '🚀 Optimal strategi (maks verdi)'
                    : '⭐ Beste valg for deg';

            final ctaLabel = locked
                ? 'Lås opp og få bedre valg'
                : state.tier == 'elite'
                    ? 'Se full strategi'
                    : 'Se hvorfor dette er best';

            final helperText = locked
                ? 'Dette valget krever $upgradeLabel for full synlighet og maksimal verdi.'
                : uplift > 0
                    ? '${best.title} kan gi deg ca. $upliftNok kr i ekstra verdi ($uplift poeng) mot standardvalget.'
                    : '${best.title} er et sterkt valg med ca. $estimatedNok kr i estimert verdi ($safePoints poeng).';

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1931),
                    Color(0xFF102847),
                    Color(0xFF0C1F36),
                  ],
                ),
                border: Border.all(
                  color: locked
                      ? const Color(0xFF7A5A1E)
                      : state.tier == 'elite'
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF315A8E),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2200A3FF),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _chip(
                        text: _tierLabel(state.tier),
                        fg: const Color(0xFF9ED1FF),
                        bg: const Color(0xFF112740),
                        border: const Color(0xFF315A8E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    best.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    best.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _chip(
                        text: 'Ca. $estimatedNok kr',
                        fg: const Color(0xFF8CFF64),
                        bg: const Color(0xFF102842),
                        border: const Color(0xFF224E77),
                      ),
                      _chip(
                        text: '+$safePoints poeng',
                        fg: const Color(0xFFB9F7A7),
                        bg: const Color(0xFF14311F),
                        border: const Color(0xFF2F6A44),
                      ),
                      if (uplift > 0)
                        _chip(
                          text: '+$upliftNok kr ekstra',
                          fg: const Color(0xFFFFC44D),
                          bg: const Color(0xFF3A2B10),
                          border: const Color(0xFF7A5A1E),
                        ),
                      if (locked)
                        _chip(
                          text: 'Krever $upgradeLabel',
                          fg: const Color(0xFFFFC44D),
                          bg: const Color(0xFF3A2B10),
                          border: const Color(0xFF7A5A1E),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    helperText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ca.-verdi er et grovt estimat basert på 0,10 kr per poeng.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onTapPaywall,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: locked
                              ? const Color(0xFF7A5A1E)
                              : const Color(0xFF4A75B1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        ctaLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chip({
    required String text,
    required Color fg,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _RecommendationState {
  final String? selectedCardId;
  final String tier;

  const _RecommendationState({
    required this.selectedCardId,
    required this.tier,
  });
}
