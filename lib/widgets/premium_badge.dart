import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final bool showBadges; // admin flag
  final bool debugBadgeEnabled; // debug/admin override
  final String text;

  const PremiumBadge({
    super.key,
    required this.isPremium,
    required this.showBadges,
    required this.debugBadgeEnabled,
    this.text = 'PRO',
  });

  @override
  Widget build(BuildContext context) {
    // Kunden kan ikke styre dette – kun admin flag / debug override.
    final visible = (showBadges && isPremium) || debugBadgeEnabled;
    if (!visible) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
