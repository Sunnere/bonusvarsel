#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_755_create_paywall_design_and_copy"

mkdir -p lib/paywall

cat > lib/paywall/paywall_content.dart <<'DART'
class PaywallPlanOption {
  final String id;
  final String title;
  final String price;
  final String subtext;
  final String badge;
  final bool highlighted;

  const PaywallPlanOption({
    required this.id,
    required this.title,
    required this.price,
    required this.subtext,
    this.badge = '',
    this.highlighted = false,
  });
}

class PaywallFeature {
  final String title;
  final String subtitle;

  const PaywallFeature({
    required this.title,
    required this.subtitle,
  });
}

class PaywallContent {
  static const String title = 'Få maks bonuspoeng – automatisk';
  static const String subtitle =
      'Se beste valg, lås opp boosts og få varsler som kan spare deg tusenvis i året.';
  static const String cta = 'Start Premium';
  static const String restore = 'Gjenopprett kjøp';
  static const String disclaimer = 'Ingen binding. Avslutt når som helst.';
  static const String valueStrip = 'Typisk verdi: 1.500–8.000 poeng per måned';

  static const List<PaywallFeature> features = [
    PaywallFeature(
      title: 'Beste valg hver gang',
      subtitle: 'Se hvor du bør handle og hvilket kort som gir mest verdi.',
    ),
    PaywallFeature(
      title: 'Premium boosts',
      subtitle: 'Lås opp høyere bonus og tydelige “Boost i Premium”-fordeler.',
    ),
    PaywallFeature(
      title: 'Varsler i sanntid',
      subtitle: 'Få beskjed når kampanjer og gode bonusmuligheter dukker opp.',
    ),
    PaywallFeature(
      title: 'Full oversikt',
      subtitle: 'Se alle butikker, kampanjer og filtre uten begrensninger.',
    ),
  ];

  static const List<PaywallPlanOption> plans = [
    PaywallPlanOption(
      id: 'monthly',
      title: 'Måned',
      price: '49 kr / mnd',
      subtext: 'Lav terskel. Perfekt for å teste.',
    ),
    PaywallPlanOption(
      id: 'yearly',
      title: 'År',
      price: '399 kr / år',
      subtext: 'Best verdi. Tilsvarer 33 kr / mnd.',
      badge: 'Mest verdi',
      highlighted: true,
    ),
  ];
}
DART

cat > lib/paywall/paywall_sheet.dart <<'DART'
import 'package:flutter/material.dart';
import 'paywall_content.dart';

class PaywallSheet extends StatefulWidget {
  final VoidCallback? onClose;
  final ValueChanged<String>? onStartPlan;
  final VoidCallback? onRestorePurchases;

  const PaywallSheet({
    super.key,
    this.onClose,
    this.onStartPlan,
    this.onRestorePurchases,
  });

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  String _selectedPlanId = PaywallContent.plans.last.id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04152A),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF03111F),
                Color(0xFF071A31),
                Color(0xFF061221),
              ],
            ),
          ),
          child: Column(
            children: [
              _TopBar(
                onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Hero(theme: theme),
                      const SizedBox(height: 18),
                      _ValueStrip(theme: theme),
                      const SizedBox(height: 18),
                      ...PaywallContent.features.map(_FeatureTile.new),
                      const SizedBox(height: 20),
                      Text(
                        'Velg abonnement',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...PaywallContent.plans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            selected: _selectedPlanId == plan.id,
                            onTap: () => setState(() => _selectedPlanId = plan.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CtaButton(
                        label: PaywallContent.cta,
                        onPressed: () => widget.onStartPlan?.call(_selectedPlanId),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          PaywallContent.disclaimer,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: widget.onRestorePurchases,
                          child: const Text(
                            PaywallContent.restore,
                            style: TextStyle(
                              color: Color(0xFF8DC3FF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Premium',
              style: TextStyle(
                color: Color(0xFFFFC44D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ThemeData theme;

  const _Hero({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F3E79),
            Color(0xFF1557A8),
            Color(0xFF0B2B59),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3300A3FF),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0xFF3B77D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _HeroIcon(icon: Icons.workspace_premium_rounded),
              SizedBox(width: 10),
              _HeroIcon(icon: Icons.flight_takeoff_rounded),
              SizedBox(width: 10),
              _HeroIcon(icon: Icons.credit_card_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            PaywallContent.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            PaywallContent.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;

  const _HeroIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _ValueStrip extends StatelessWidget {
  final ThemeData theme;

  const _ValueStrip({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1E36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D406B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFC44D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              PaywallContent.valueStrip,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final PaywallFeature feature;

  const _FeatureTile(this.feature);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF08172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF153357)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF173A63),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: Color(0xFF9ED1FF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PaywallPlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF63B4FF) : const Color(0xFF173357);
    final fillColor = selected ? const Color(0xFF0E2B4F) : const Color(0xFF08172A);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x2600A3FF),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF8DC3FF) : Colors.white54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      if (plan.badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC44D),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            plan.badge,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.price,
                    style: const TextStyle(
                      color: Color(0xFF9ED1FF),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subtext,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _CtaButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF5EA8FF),
          foregroundColor: const Color(0xFF04152A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
DART

cat > lib/paywall/paywall_preview_page.dart <<'DART'
import 'package:flutter/material.dart';
import 'paywall_sheet.dart';

class PaywallPreviewPage extends StatelessWidget {
  const PaywallPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PaywallSheet(
      onClose: () => Navigator.of(context).maybePop(),
      onStartPlan: (planId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Valgt plan: $planId')),
        );
      },
      onRestorePurchases: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gjenopprett kjøp trykket')),
        );
      },
    );
  }
}
DART

cat > lib/paywall/paywall_usage_example.txt <<'TXT'
Bruk paywall-preview slik fra en knapp/page:

import 'package:flutter/material.dart';
import 'paywall/paywall_preview_page.dart';

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const PaywallPreviewPage(),
  ),
);

For bunndialog:

showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => const FractionallySizedBox(
    heightFactor: 0.96,
    child: PaywallPreviewPage(),
  ),
);
TXT

echo "✅ Laget:"
echo " - lib/paywall/paywall_content.dart"
echo " - lib/paywall/paywall_sheet.dart"
echo " - lib/paywall/paywall_preview_page.dart"
echo " - lib/paywall/paywall_usage_example.txt"
echo
echo "Neste:"
echo "1) åpne paywall-preview fra en midlertidig knapp eller route"
echo "2) test tekst/flyt i appen"
echo "3) wire mot ekte kjøpslogikk etterpå"
