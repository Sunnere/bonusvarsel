import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';

/// Result from AdminDialog
class AdminDialogResult {
  final SubscriptionTier tier;
  final bool showBadges;
  final int freeLimit;

  const AdminDialogResult({
    required this.tier,
    required this.showBadges,
    required this.freeLimit,
  });
}

/// Simple helper labels (so we don't depend on other extensions)

/// Debug/admin dialog to tweak subscription settings.
/// Usage:
// final res = await showDialog<AdminDialogResult>(context: ctx, builder: (_) => AdminDialog(...));
class AdminDialog extends StatefulWidget {
  final SubscriptionTier tier;
  final bool showBadges;
  final int freeLimit;

  const AdminDialog({
    super.key,
    required this.tier,
    required this.showBadges,
    required this.freeLimit,
  });

  @override
  State<AdminDialog> createState() => _AdminDialogState();
}

class _AdminDialogState extends State<AdminDialog> {
  late SubscriptionTier _tier;
  late bool _showBadges;
  late TextEditingController _freeLimitCtrl;

  @override
  void initState() {
    super.initState();
    _tier = widget.tier;
    _showBadges = widget.showBadges;
    _freeLimitCtrl = TextEditingController(text: widget.freeLimit.toString());
  }

  @override
  void dispose() {
    _freeLimitCtrl.dispose();
    super.dispose();
  }

  int _parseFreeLimit() {
    final n = int.tryParse(_freeLimitCtrl.text.trim()) ?? widget.freeLimit;
    if (n < 1) return 1;
    if (n > 999) return 999;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin (debug)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<SubscriptionTier>(
              initialValue: _tier,
              decoration: const InputDecoration(
                labelText: 'Tier',
                border: OutlineInputBorder(),
              ),
              items: SubscriptionTier.values
                  .map(
                    (t) => DropdownMenuItem<SubscriptionTier>(
                      value: t,
                      child: Text(
                        switch (t) {
                          SubscriptionTier.free => 'Free',
                          SubscriptionTier.pro => 'Pro',
                          SubscriptionTier.elite => 'Elite',
                        },
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _tier = v);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vis badges'),
              value: _showBadges,
              onChanged: (v) => setState(() => _showBadges = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _freeLimitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Free limit',
                helperText: '1–999',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () {
            final res = AdminDialogResult(
              tier: _tier,
              showBadges: _showBadges,
              freeLimit: _parseFreeLimit(),
            );
            Navigator.of(context).pop(res);
          },
          child: const Text('Lagre'),
        ),
      ],
    );
  }
}
