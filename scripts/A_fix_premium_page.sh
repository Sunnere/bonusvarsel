#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
mkdir -p lib/pages
[ -f "$FILE" ] && cp "$FILE" "$FILE.bak.$(date +%s)" || true

cat > "$FILE" <<'DART'
import 'package:flutter/material.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final premium = PremiumService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<bool>(
          future: premium.getIsPremium(),
          builder: (context, snap) {
            final isPremium = snap.data == true;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium
                      ? 'Premium er aktivert ✅'
                      : 'Premium gir deg flere filtre, varsler og bedre oversikt.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium, color: cs.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '• Favoritt-prioritering\n'
                            '• Ekstra filtre (min poeng, sortering)\n'
                            '• Tidlig tilgang til nye funksjoner',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Her kobler vi på betaling/fordeler (placeholder).'),
                        ),
                      );
                    },
                    child: Text(isPremium ? 'Administrer Premium' : 'Oppgrader til Premium'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final ok = await premium.restore();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Gjenopprettet ✅' : 'Ingenting å gjenopprette'),
                        ),
                      );
                    },
                    child: const Text('Gjenopprett kjøp'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
DART

dart format "$FILE" >/dev/null
flutter analyze || true
echo "✅ A ferdig: premium_page.dart fikset"
