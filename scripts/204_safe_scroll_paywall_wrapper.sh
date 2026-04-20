#!/usr/bin/env bash
set -euo pipefail

mkdir -p lib/widgets

cat > lib/widgets/paywall_scroll_wrapper.dart <<'DART'
import 'package:flutter/material.dart';
import '../services/paywall_trigger_service.dart';

class PaywallScrollWrapper extends StatefulWidget {
  final Widget child;

  const PaywallScrollWrapper({
    super.key,
    required this.child,
  });

  @override
  State<PaywallScrollWrapper> createState() => _PaywallScrollWrapperState();
}

class _PaywallScrollWrapperState extends State<PaywallScrollWrapper> {
  final ScrollController _controller = ScrollController();
  bool _triggered = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() async {
      if (_controller.offset > 600 && !_triggered) {
        _triggered = true;

        final seen =
            await PaywallTriggerService.hasSeenScrollDepth();

        if (!seen && context.mounted) {
          await PaywallTriggerService.markScrollDepthSeen();

          await PaywallTriggerService.showPaywall(
            context,
            source: 'scroll_wrapper',
            title: 'Få mer ut av bonusen',
            subtitle:
                'Premium gir høyere poengrate og smartere valg – så du tjener mer.',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      child: widget.child,
    );
  }
}
DART

echo "Opprettet paywall_scroll_wrapper.dart"

echo
echo "Neste steg:"
echo "1. Wrap EbShoppingPage med PaywallScrollWrapper"
echo "2. Kjør flutter analyze"
echo "3. Kjør flutter test"
