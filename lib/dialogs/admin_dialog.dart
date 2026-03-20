import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';

class AdminDebugResult {
  final SubscriptionTier tier;
  final bool showBadges;
  final int freeLimit;

  const AdminDebugResult({
    required this.tier,
    required this.showBadges,
    required this.freeLimit,
  });
}

Future<AdminDebugResult?> openDebugAdminDialog(
  BuildContext context, {
  required SubscriptionTier initialTier,
  required bool initialShowBadges,
  required int initialFreeLimit,
}) {
  SubscriptionTier tier = initialTier;
  bool showBadges = initialShowBadges;
  double freeLimit = initialFreeLimit.toDouble();

  return showDialog<AdminDebugResult>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Admin (debug)'),
        content: StatefulBuilder(
          builder: (ctx, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SubscriptionTier>(
                  initialValue: tier,
                  items: SubscriptionTier.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.label} (${t.name})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => tier = v);
                  },
                  decoration: const InputDecoration(labelText: 'Tier'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Show badges')),
                    Switch(
                      value: showBadges,
                      onChanged: (v) => setLocal(() => showBadges = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Free limit'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        min: 5,
                        max: 200,
                        divisions: 39,
                        label: freeLimit.round().toString(),
                        value: freeLimit,
                        onChanged: (v) => setLocal(() => freeLimit = v),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                AdminDebugResult(
                  tier: tier,
                  showBadges: showBadges,
                  freeLimit: freeLimit.round(),
                ),
              );
            },
            child: const Text('Lagre'),
          ),
        ],
      );
    },
  );
}
