import 'package:flutter/material.dart';

class PaywallRealPurchaseFlow {
  static const String premiumRouteName = '/premium';

  static Future<void> startPurchaseFlow(
    BuildContext context, {
    required String planId,
  }) async {
    final args = <String, dynamic>{
      'source': 'paywall',
      'action': 'purchase',
      'planId': planId,
      'billingCycle': planId,
    };

    final localNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final route = ModalRoute.of(context);

    // Hvis paywall ligger i popup/dialog/bottomsheet, lukk den først.
    if (route is PopupRoute && localNavigator.canPop()) {
      localNavigator.pop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    try {
      await rootNavigator.pushNamed(premiumRouteName, arguments: args);
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fant ikke /premium-route. Koble Premium-siden til named route.',
          ),
        ),
      );
    }
  }

  static Future<void> restorePurchases(BuildContext context) async {
    final args = <String, dynamic>{
      'source': 'paywall',
      'action': 'restore',
    };

    final localNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final route = ModalRoute.of(context);

    if (route is PopupRoute && localNavigator.canPop()) {
      localNavigator.pop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    try {
      await rootNavigator.pushNamed(premiumRouteName, arguments: args);
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fant ikke /premium-route. Koble Premium-siden til named route.',
          ),
        ),
      );
    }
  }
}
