#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/checkout_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_713_replace_checkout_page_with_clean_coming_soon"
echo "✅ Backup laget: ${FILE}.bak_713_replace_checkout_page_with_clean_coming_soon"

cat > "$FILE" <<'DART'
import 'package:flutter/material.dart';
import '../services/checkout_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String billing = CheckoutService.instance.billing;

  @override
  Widget build(BuildContext context) {
    final checkout = CheckoutService.instance;
    final plan = checkout.plan.toLowerCase();
    final isElite = plan == 'elite';

    final accent = isElite
        ? const Color(0xFFD4AF37)
        : const Color(0xFF22C55E);

    final monthlyPrice = isElite ? 89 : 49;
    final yearlyPrice = isElite ? 890 : 490;
    final monthlyEquivalent = (yearlyPrice / 12).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isElite ? 'Elite' : 'Premium'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isElite
                        ? const [Color(0xFF1E1B13), Color(0xFFD4AF37)]
                        : const [Color(0xFF052E1C), Color(0xFF22C55E)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isElite
                          ? 'Maksimer alle poeng'
                          : 'Tjen flere poeng automatisk',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isElite
                          ? 'Opptil 8 000+ poeng per måned'
                          : 'Typisk 1 500–4 000 ekstra poeng per måned',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _PriceOption(
                      label: 'Månedlig',
                      price: '$monthlyPrice kr',
                      selected: billing == 'monthly',
                      onTap: () async {
                        setState(() => billing = 'monthly');
                        await CheckoutService.instance.setBilling('monthly');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PriceOption(
                      label: 'Årlig',
                      price: '$yearlyPrice kr',
                      sub: '$monthlyEquivalent kr/mnd',
                      badge: '2 mnd gratis',
                      selected: billing == 'yearly',
                      onTap: () async {
                        setState(() => billing = 'yearly');
                        await CheckoutService.instance.setBilling('yearly');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Text(
                  'Betaling og aktivering kommer snart. Du kan allerede se nivåene og hva som inngår.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _featureRow('Flere butikker'),
                    _featureRow('Høyere poengrate'),
                    if (isElite) _featureRow('Flere programmer'),
                    _featureRow('Smartere valg'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (!isElite)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.40),
                    ),
                  ),
                  child: const Text(
                    'Elite gir deg flere programmer og enda høyere opptjening.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kommer snart')),
                    );
                  },
                  child: const Text(
                    'Kommer snart',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kommer snart')),
                  );
                },
                child: const Text('Kommer snart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceOption extends StatelessWidget {
  final String label;
  final String price;
  final String? sub;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PriceOption({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.sub,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
            if (sub != null)
              Text(
                sub!,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.black54 : Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
DART

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
