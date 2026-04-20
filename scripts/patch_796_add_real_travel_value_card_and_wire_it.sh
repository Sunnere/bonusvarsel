#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_796_add_real_travel_value_card_and_wire_it"

TARGET="lib/pages/travel_page.dart"
WIDGET="lib/widgets/travel_value_card.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

mkdir -p lib/widgets

cp "$TARGET" "$TARGET.bak_796_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

cat > "$WIDGET" <<'DART'
import 'package:flutter/material.dart';

import '../models/subscription_tier.dart';
import '../services/bonus_recommendation_engine.dart';
import '../services/subscription_service.dart';
import '../services/user_state.dart';

class TravelValueCard extends StatelessWidget {
  final double amountNok;
  final String selectedProgram;

  const TravelValueCard({
    super.key,
    required this.amountNok,
    required this.selectedProgram,
  });

  static const double _nokPerPoint = 0.10;

  Future<_TravelState> _loadState() async {
    final selectedCardId = await UserState.getSelectedCardId();
    final tierEnum = await SubscriptionService.instance.getTier();

    final tier = switch (tierEnum) {
      SubscriptionTier.elite => 'elite',
      SubscriptionTier.pro => 'premium',
      SubscriptionTier.free => 'free',
    };

    return _TravelState(
      selectedCardId: selectedCardId,
      tier: tier,
    );
  }

  static int _pointsToNok(int points) {
    if (points <= 0) return 0;
    return (points * _nokPerPoint).round();
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

  @override
  Widget build(BuildContext context) {
    if (amountNok <= 0) return const SizedBox.shrink();

    return FutureBuilder<_TravelState>(
      future: _loadState(),
      builder: (context, snap) {
        final state = snap.data ??
            const _TravelState(
              selectedCardId: null,
              tier: 'free',
            );

        final travel = BonusRecommendationEngine.recommendForTravel(
          amountNok: amountNok,
          selectedCardId: state.selectedCardId,
          tier: state.tier,
          favorite: false,
        );

        final points = travel.totalPoints;
        final nok = _pointsToNok(points);

        final helper = state.selectedCardId == null || state.selectedCardId!.isEmpty
            ? 'Velg et kort for et mer realistisk estimat.'
            : 'Estimert verdi er basert på valgt kort og nåværende nivå.';

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reiseverdi akkurat nå',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _pill(_tierLabel(state.tier)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                selectedProgram,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _metricChip('Ca. $nok kr'),
                  _metricChip('$points poeng'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                helper,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ca.-verdi er et grovt estimat basert på 0,10 kr per poeng.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF112740),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF315A8E)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9ED1FF),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF102842),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF224E77)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8CFF64),
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _TravelState {
  final String? selectedCardId;
  final String tier;

  const _TravelState({
    required this.selectedCardId,
    required this.tier,
  });
}
DART

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
report = []

widget_import = "import '../widgets/travel_value_card.dart';"
if widget_import not in text:
    imports = list(re.finditer(r"^import .+?;\n", text, flags=re.MULTILINE))
    if imports:
        last = imports[-1]
        text = text[:last.end()] + widget_import + "\n" + text[last.end():]
    else:
        text = widget_import + "\n" + text
    report.append("la til import for travel_value_card.dart")

# prøv å legge widgeten rett etter estimate-labelen
snippet = """
              const SizedBox(height: 8),
              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
"""

if "TravelValueCard(" not in text:
    pattern = r"('Foreløpig estimat'|'Estimert opptjening')"
    text2, n = re.subn(pattern, r"\1", text, count=1)
    if n:
        # sett widgeten inn etter linjen som lager estPoints
        text3, n2 = re.subn(
            r"(final amount = _amount\(\);\n\s*final estPoints = _estimatePoints\(amount\);\n)",
            r"\1",
            text2,
            count=1,
        )
        text = text3
        # prøv å injisere etter tekstlinjen som viser poeng
        text4, n4 = re.subn(
            r"(\$estPoints poeng',\n\s*style:[^\n]+\n\s*\),)",
            r"\1" + snippet,
            text,
            count=1,
        )
        if n4:
            text = text4
            report.append("la til TravelValueCard under poeng-estimatet")
        else:
            report.append("ADVARSEL: fant ikke trygg plass under poeng-estimatet")
    else:
        report.append("ADVARSEL: fant ikke estimate-seksjonen i travel_page.dart")
else:
    report.append("TravelValueCard finnes allerede")

path.write_text(text)
Path("lib/services/_patch_796_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/services/_patch_796_report.txt || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) flutter run"
echo "3) test Reise med og uten valgt kort"
