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

        final seen = await PaywallTriggerService.hasSeenScrollDepth();

        if (!seen && context.mounted) {
          if (!mounted) return;

          await PaywallTriggerService.showPaywall(
            context,
            source: 'shopping_scroll',
            title: 'Lås opp Premium-fordeler',
            subtitle:
                'Premium gir høyere bonusrate, smartere valg og bedre oversikt.',
          );

          await PaywallTriggerService.markScrollDepthSeen();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      child: widget.child,
    );
  }
}
