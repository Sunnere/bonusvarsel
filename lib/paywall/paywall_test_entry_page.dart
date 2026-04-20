import 'package:flutter/material.dart';
import 'paywall_preview_page.dart';

class PaywallTestEntryPage extends StatelessWidget {
  const PaywallTestEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04152A),
      appBar: AppBar(
        title: const Text('Paywall test'),
        backgroundColor: const Color(0xFF04152A),
      ),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.workspace_premium_rounded),
          label: const Text('Åpne Premium paywall'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PaywallPreviewPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}
