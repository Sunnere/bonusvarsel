import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';

class PaywallPage extends StatelessWidget {
  final SubscriptionService subs;

  PaywallPage({super.key, SubscriptionService? subs})
      : subs = subs ?? SubscriptionService.instance;

  Future<void> _select(BuildContext context, SubscriptionTier tier) async {
    await subs.setTier(tier);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oppgrader')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Tile(
              title: 'Pro',
              subtitle: 'Grønne premium-toner + flere features',
              onTap: () => _select(context, SubscriptionTier.pro),
            ),
            const SizedBox(height: 12),
            _Tile(
              title: 'Elite',
              subtitle: 'Svart/gull/lilla – full “luksus”',
              onTap: () => _select(context, SubscriptionTier.elite),
            ),
            const SizedBox(height: 12),
            _Tile(
              title: 'Free',
              subtitle: 'Gratis – minimal blå',
              onTap: () => _select(context, SubscriptionTier.free),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surface,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
