import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../models/activated_notification.dart';
import '../services/api_service.dart';

class BonusvarselNotificationsPage extends StatefulWidget {
  const BonusvarselNotificationsPage({super.key});

  @override
  State<BonusvarselNotificationsPage> createState() =>
      _BonusvarselNotificationsPageState();
}

class _BonusvarselNotificationsPageState
    extends State<BonusvarselNotificationsPage> {
  late Future<Map<String, dynamic>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load({bool reset = false}) {
    _future = ApiService.getActivatedNotifications(reset: reset);
  }

  Future<void> _refresh({bool reset = false}) async {
    setState(() {
      _busy = true;
      _load(reset: reset);
    });
    try {
      await _future;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'boost':
        return Colors.orange;
      case 'premium':
        return Colors.blue;
      case 'elite':
        return const Color(0xFFD4AF37);
      default:
        return Colors.grey;
    }
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1F4D),
            Color(0xFF2F80ED),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activated Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.surface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tester backend-motoren for kampanjer som akkurat har blitt aktive.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(ActivatedNotification item) {
    final color = _levelColor(item.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.body),
            const SizedBox(height: 6),
            Text(
              '${item.store} • ${item.source.toUpperCase()} • ${item.category}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              'expires: ${item.expires}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: color.withValues(alpha: 0.12),
          ),
          child: Text(
            item.level.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _busy ? null : () => _refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _busy ? null : () => _refresh(reset: true),
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset + refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Feil: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              );
            }

            final data = snapshot.data ?? <String, dynamic>{};
            final count = data['count'] ?? 0;
            final seenCount = data['seenCount'] ?? 0;
            final items =
                (data['notifications'] as List<ActivatedNotification>? ?? const []);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nye varsler: $count\nSett som sett: $seenCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _busy ? null : () => _refresh(reset: true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text('Ingen nye aktiverte kampanjer akkurat nå.'),
                  )
                else
                  ...items.map(_notificationCard),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
