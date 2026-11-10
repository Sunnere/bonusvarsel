import 'package:flutter/material.dart';
import '../pages/checkout_page.dart';
import '../services/checkout_service.dart';
import '../services/entitlement_service.dart';

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
    final messenger = ScaffoldMessenger.of(context);

    try {
      EntitlementService.lastIapDebug = '';
      await CheckoutService.instance.restorePurchases();
      messenger.showSnackBar(
        const SnackBar(content: Text('Gjenoppretting startet - vent noen sekunder...')),
      );
      await Future<void>.delayed(const Duration(seconds: 6));
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            EntitlementService.lastIapDebug.isEmpty
                ? 'Apple fant ingen kjøp å gjenopprette for denne Apple-ID-en.'
                : EntitlementService.lastIapDebug,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Kunne ikke gjenopprette: $e')),
      );
    }
  }
}
