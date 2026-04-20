#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/checkout_page.dart"

mkdir -p lib/pages

cat > "$FILE" <<'DART'
import 'package:flutter/material.dart';
import '../services/checkout_service.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = CheckoutService.instance;

    final plan = checkout.plan.toLowerCase();
    final billing = checkout.billing;

    final isElite = plan == 'elite';

    return Scaffold(
      appBar: AppBar(
        title: Text(isElite ? 'Elite' : 'Premium'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isElite ? 'Maksimer alle poeng' : 'Få flere poeng uten ekstra arbeid',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              billing == 'yearly'
                  ? 'Årlig betaling gir deg mest verdi – spar flere måneder.'
                  : 'Månedlig gir fleksibilitet uten binding.',
            ),

            const SizedBox(height: 20),

            if (!isElite) ...[
              const Text(
                'Hvorfor oppgradere til Elite?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Flere programmer (SAS + Trumf + mer)'),
              const Text('• Høyere opptjening totalt'),
              const Text('• Bedre prioritering av tilbud'),
              const SizedBox(height: 20),
            ],

            const Text(
              'Hvorfor velge årlig?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Lavere pris per måned'),
            const Text('• Mindre friksjon'),
            const Text('• Maks verdi over tid'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Stripe / IAP
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Start betaling (kommer snart)')),
                  );
                },
                child: Text(
                  billing == 'yearly'
                      ? 'Start årlig abonnement'
                      : 'Start månedlig abonnement',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

echo "✅ CheckoutPage laget"
