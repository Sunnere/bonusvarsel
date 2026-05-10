#!/bin/bash
cp lib/paywall/paywall_real_purchase_flow.dart lib/paywall/paywall_real_purchase_flow.dart.bak

cat > lib/paywall/paywall_real_purchase_flow.dart << 'DART'
import 'package:flutter/material.dart';
import '../pages/checkout_page.dart';
import '../services/checkout_service.dart';

class PaywallRealPurchaseFlow {
  static Future<void> startPurchaseFlow(
    BuildContext context, {
    required String planId,
  }) async {
    final localNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final route = ModalRoute.of(context);

    // Bestem plan og billing fra planId
    String plan = 'Premium';
    String billing = 'monthly';

    if (planId.toLowerCase().contains('elite')) {
      plan = 'Elite';
    }
    if (planId.toLowerCase().contains('year')) {
      billing = 'yearly';
    }

    // Sett valg i CheckoutService
    await CheckoutService.instance.setSelection(
      plan: plan,
      billing: billing,
    );

    // Lukk paywall hvis den er i popup/dialog
    if (route is PopupRoute && localNavigator.canPop()) {
      localNavigator.pop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    if (!context.mounted) return;

    // Gå direkte til CheckoutPage — ikke via PremiumPage
    await rootNavigator.push(
      MaterialPageRoute(
        builder: (_) => const CheckoutPage(),
      ),
    );
  }

  static Future<void> restorePurchases(BuildContext context) async {
    final localNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final route = ModalRoute.of(context);

    if (route is PopupRoute && localNavigator.canPop()) {
      localNavigator.pop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    if (!context.mounted) return;

    try {
      await CheckoutService.instance.restorePurchases();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gjenoppretting startet.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke gjenopprette: $e')),
      );
    }
  }
}
DART

echo "✅ paywall_real_purchase_flow.dart oppdatert"
echo "   - Går nå direkte til CheckoutPage"
echo "   - Ikke via PremiumPage lenger"
echo "   - Plan og billing settes fra planId"
