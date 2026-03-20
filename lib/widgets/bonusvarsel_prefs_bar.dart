import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BonusvarselPrefsBar extends StatefulWidget {
  final VoidCallback onChanged;

  const BonusvarselPrefsBar({
    super.key,
    required this.onChanged,
  });

  @override
  State<BonusvarselPrefsBar> createState() => _BonusvarselPrefsBarState();
}

class _BonusvarselPrefsBarState extends State<BonusvarselPrefsBar> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _busy,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonal(
            onPressed: () => _run(() async {
              await ApiService.updatePrefs(
                sources: const ['sas', 'trumf'],
                categories: const [],
                minRate: 0,
                onlyCampaigns: false,
                favFirst: false,
              );
            }),
            child: const Text('Alle'),
          ),
          FilledButton.tonal(
            onPressed: () => _run(() async {
              await ApiService.updatePrefs(
                sources: const ['sas'],
                categories: const ['electronics'],
                minRate: 10,
                onlyCampaigns: false,
                favFirst: false,
              );
            }),
            child: const Text('SAS electronics'),
          ),
          FilledButton.tonal(
            onPressed: () => _run(() async {
              await ApiService.updatePrefs(
                onlyCampaigns: true,
              );
            }),
            child: const Text('Kun kampanjer'),
          ),
          OutlinedButton(
            onPressed: () => _run(() async {
              await ApiService.updatePrefs(
                sources: const ['sas', 'trumf'],
                categories: const [],
                minRate: 0,
                onlyCampaigns: false,
                favFirst: false,
              );
            }),
            child: const Text('Reset'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
