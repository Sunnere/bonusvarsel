#!/bin/bash
set -e

cat > ~/bonusvarsel/lib/pages/bonusvarsel_paywall_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../paywall/paywall_preview_page.dart';

class BonusvarselPaywallPage extends StatelessWidget {
  const BonusvarselPaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaywallPreviewPage();
  }
}
DART

echo "✅ bonusvarsel_paywall_page.dart erstattet med ekte IAP-paywall"
