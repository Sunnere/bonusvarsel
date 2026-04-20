import 'package:flutter/material.dart';
import 'paywall_preview_page.dart';

class PaywallLauncherButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;

  const PaywallLauncherButton({
    super.key,
    this.tooltip = 'Test Premium paywall',
    this.icon = Icons.workspace_premium_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PaywallPreviewPage(),
          ),
        );
      },
    );
  }
}
