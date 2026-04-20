#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_781_wire_selected_card_tier_favorites_safely"

TARGET="lib/pages/eb_shopping_page.dart"
WIDGET="lib/widgets/best_recommendation_card.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

if [ ! -f "$WIDGET" ]; then
  echo "❌ Fant ikke $WIDGET"
  echo "Kjør først patch_780."
  exit 1
fi

cp "$TARGET" "$TARGET.bak_781_$(date +%Y%m%d_%H%M%S)"
cp "$WIDGET" "$WIDGET.bak_781_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

cat > "$WIDGET" <<'DART'
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bonus_recommendation.dart';
import '../services/bonus_recommendation_engine.dart';

class BestRecommendationCard extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final double amountNok;
  final String? selectedCardId;
  final String tier;
  final Set<String> favoriteIds;
  final Map<String, dynamic>? currentSelection;
  final VoidCallback? onTapPaywall;

  const BestRecommendationCard({
    super.key,
    required this.offers,
    required this.amountNok,
    required this.selectedCardId,
    required this.tier,
    this.favoriteIds = const {},
    this.currentSelection,
    this.onTapPaywall,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();

    final recommendations = BonusRecommendationEngine.recommendForShopping(
      offers: offers,
      amountNok: amountNok,
      selectedCardId: selectedCardId,
      tier: tier,
      favoriteIds: favoriteIds,
      currentSelection: currentSelection,
    );

    if (recommendations.isEmpty) return const SizedBox.shrink();

    final best = recommendations.first;
    final uplift = best.upliftVsCurrent ?? 0;
    final locked = best.requiredTier != BonusTier.free && tier == 'free';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      padding: const EdgeInsets.all(16),
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
        border: Border.all(color: const Color(0xFF315A8E)),
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
              const Expanded(
                child: Text(
                  '⭐ Beste valg akkurat nå',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (locked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2B10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF7A5A1E)),
                  ),
                  child: const Text(
                    'Låst',
                    style: TextStyle(
                      color: Color(0xFFFFC44D),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            best.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            best.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(
                text: '${best.estimatedPoints} poeng',
                fg: const Color(0xFF8CFF64),
                bg: const Color(0xFF102842),
                border: const Color(0xFF224E77),
              ),
              if (uplift > 0)
                _chip(
                  text: '+$uplift vs vanlig',
                  fg: const Color(0xFFFFC44D),
                  bg: const Color(0xFF3A2B10),
                  border: const Color(0xFF7A5A1E),
                ),
              if (best.favorite)
                _chip(
                  text: 'Favoritt',
                  fg: const Color(0xFFB8F5A9),
                  bg: const Color(0xFF1B2D20),
                  border: const Color(0xFF365C3F),
                ),
              _chip(
                text: _tierLabel(tier),
                fg: const Color(0xFF9ED1FF),
                bg: const Color(0xFF112740),
                border: const Color(0xFF315A8E),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            BonusRecommendationEngine.recommendationSummary(
              recommendation: best,
            ),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTapPaywall,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF4A75B1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    locked ? 'Lås opp' : 'Se hvorfor',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _chip({
    required String text,
    required Color fg,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class SmartBestRecommendationCard extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final double amountNok;
  final Map<String, dynamic>? currentSelection;
  final VoidCallback? onTapPaywall;

  const SmartBestRecommendationCard({
    super.key,
    required this.offers,
    required this.amountNok,
    this.currentSelection,
    this.onTapPaywall,
  });

  Future<_SmartBonusState> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final selectedCardId = _firstString(
      prefs,
      const [
        'selected_card_id',
        'selectedCardId',
        'user_selected_card_id',
        'card_id',
      ],
    );

    final tier = _resolveTier(prefs);
    final favoriteIds = _resolveFavorites(prefs);

    return _SmartBonusState(
      selectedCardId: selectedCardId,
      tier: tier,
      favoriteIds: favoriteIds,
    );
  }

  static String? _firstString(SharedPreferences prefs, List<String> keys) {
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String _resolveTier(SharedPreferences prefs) {
    final direct = _firstString(
      prefs,
      const [
        'subscription_tier',
        'premium_tier',
        'user_tier',
        'tier',
        'plan_tier',
      ],
    );

    if (direct != null) {
      final normalized = direct.toLowerCase();
      if (normalized.contains('elite')) return 'elite';
      if (normalized.contains('premium')) return 'premium';
    }

    final eliteFlags = [
      prefs.getBool('is_elite') ?? false,
      prefs.getBool('elite_enabled') ?? false,
      prefs.getBool('has_elite') ?? false,
    ];
    if (eliteFlags.any((v) => v)) return 'elite';

    final premiumFlags = [
      prefs.getBool('is_premium') ?? false,
      prefs.getBool('premium_enabled') ?? false,
      prefs.getBool('has_premium') ?? false,
      prefs.getBool('premium_active') ?? false,
    ];
    if (premiumFlags.any((v) => v)) return 'premium';

    return 'free';
  }

  static Set<String> _resolveFavorites(SharedPreferences prefs) {
    final out = <String>{};

    for (final key in const [
      'favorite_store_ids',
      'favoriteStoreIds',
      'favorites',
      'favorite_ids',
    ]) {
      final list = prefs.getStringList(key);
      if (list != null) {
        out.addAll(list.map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
    }

    for (final key in const [
      'favorites_json',
      'favorite_stores_json',
      'favoriteStoreIdsJson',
    ]) {
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          out.addAll(decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
        }
      } catch (_) {
        // ignore bad JSON
      }
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SmartBonusState>(
      future: _loadState(),
      builder: (context, snapshot) {
        final state = snapshot.data ??
            const _SmartBonusState(
              selectedCardId: null,
              tier: 'free',
              favoriteIds: {},
            );

        return BestRecommendationCard(
          offers: offers,
          amountNok: amountNok,
          selectedCardId: state.selectedCardId,
          tier: state.tier,
          favoriteIds: state.favoriteIds,
          currentSelection: currentSelection,
          onTapPaywall: onTapPaywall,
        );
      },
    );
  }
}

class _SmartBonusState {
  final String? selectedCardId;
  final String tier;
  final Set<String> favoriteIds;

  const _SmartBonusState({
    required this.selectedCardId,
    required this.tier,
    required this.favoriteIds,
  });
}
DART

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()
report = []

# Replace only the safe widget call
old_pattern = re.compile(
    r"""BestRecommendationCard\(
                offers:\s*items\.whereType<Map<String, dynamic>>\(\)\.toList\(\),
                amountNok:\s*5000,
                selectedCardId:\s*null,
                tier:\s*'free',
                favoriteIds:\s*const \{\},
                onTapPaywall:\s*_openRecommendationPaywall,
              \),""",
    re.DOTALL,
)

new_snippet = """SmartBestRecommendationCard(
                offers: items.whereType<Map<String, dynamic>>().toList(),
                amountNok: 5000,
                onTapPaywall: _openRecommendationPaywall,
              ),"""

text2, n = old_pattern.subn(new_snippet, text, count=1)
if n:
    text = text2
    report.append("erstattet BestRecommendationCard(...) med SmartBestRecommendationCard(...)")
else:
    report.append("ADVARSEL: fant ikke eksakt eksisterende recommendation-kall; ingen wiring endret")

path.write_text(text)
Path("lib/services/_patch_781_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/services/_patch_781_report.txt || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) flutter run"
echo "3) åpne EB Shopping og test kort / nivå / favoritt-effekt"
