import 'package:flutter/material.dart';
import 'paywall_sheet.dart';
import 'paywall_real_purchase_flow.dart';

class PaywallPreviewPage extends StatelessWidget {
  const PaywallPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PaywallSheet(
      onClose: () => Navigator.of(context).maybePop(),
      onStartPlan: (planId) => PaywallRealPurchaseFlow.startPurchaseFlow(
        context,
        planId: planId,
      ),
      onRestorePurchases: () => PaywallRealPurchaseFlow.restorePurchases(context),
    );
  }
}
