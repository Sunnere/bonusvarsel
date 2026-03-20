import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';
import 'paywall_page.dart';

class TravelClubPage extends StatelessWidget {
  final SubscriptionService subs;

  TravelClubPage({super.key, SubscriptionService? subs})
      : subs = subs ?? SubscriptionService.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: subs,
      builder: (context, _) {
        return FutureBuilder<SubscriptionTier>(
          future: subs.getTier(),
          builder: (context, snap) {
            final tier = snap.data ?? SubscriptionTier.free;
            final isPro = tier == SubscriptionTier.pro;
            final isElite = tier == SubscriptionTier.elite;

            return Scaffold(
              appBar: AppBar(title: const Text('Travel Club')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tier: ${tier.title}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      isElite
                          ? 'Elite: Luksus-funksjoner aktivert ✅'
                          : isPro
                              ? 'Pro: Premium-funksjoner aktivert ✅'
                              : 'Free: Basis (annonser + begrensninger)',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaywallPage(subs: subs),
                          ),
                        );
                      },
                      child: const Text('Oppgrader til Pro/Elite'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
