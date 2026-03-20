import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../models/activated_notification.dart';
import '../models/push_dispatch_preview.dart';
import '../services/api_service.dart';

class BonusvarselPushPreviewPage extends StatefulWidget {
  const BonusvarselPushPreviewPage({super.key});

  @override
  State<BonusvarselPushPreviewPage> createState() =>
      _BonusvarselPushPreviewPageState();
}

class _BonusvarselPushPreviewPageState
    extends State<BonusvarselPushPreviewPage> {
  late Future<Map<String, dynamic>> _notificationsFuture;
  late Future<Map<String, dynamic>> _dispatchFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load({bool reset = false}) {
    _notificationsFuture = ApiService.getActivatedNotifications(reset: reset);
    _dispatchFuture = ApiService.getPushDispatchPreview(reset: reset);
  }

  Future<void> _refresh({bool reset = false}) async {
    setState(() {
      _busy = true;
      _load(reset: reset);
    });

    try {
      await Future.wait<dynamic>([
        _notificationsFuture,
        _dispatchFuture,
      ]);
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
            'Push Preview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.surface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Viser hele kjeden fra aktiverte kampanjer til push dispatch preview.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _statsCard({
    required int notificationCount,
    required int seenCount,
    required int deviceCount,
    required int dispatchCount,
  }) {
    return Container(
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
              'Nye varsler: $notificationCount\nSett: $seenCount\nDevices: $deviceCount\nDispatches: $dispatchCount',
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
        subtitle: Text(
          '${item.body}\n${item.store} • ${item.source.toUpperCase()} • ${item.category}',
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: color.withAlpha(30),
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

  Widget _dispatchCard(PushDispatchPreview item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: const Icon(Icons.send_outlined),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${item.body}\n${item.platform} • ${item.deviceToken}\nstatus: ${item.status}',
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Preview'),
        actions: [
          IconButton(
            onPressed: _busy ? null : () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _busy ? null : () => _refresh(reset: true),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait<dynamic>([
            _notificationsFuture,
            _dispatchFuture,
          ]),
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

            final notificationsData = snapshot.data![0] as Map<String, dynamic>;
            final dispatchData = snapshot.data![1] as Map<String, dynamic>;

            final notifications =
                notificationsData['notifications'] as List<ActivatedNotification>? ??
                    const [];
            final dispatches =
                dispatchData['dispatches'] as List<PushDispatchPreview>? ?? const [];

            final notificationCount = notificationsData['count'] ?? 0;
            final seenCount = notificationsData['seenCount'] ?? 0;
            final deviceCount = dispatchData['deviceCount'] ?? 0;
            final dispatchCount = dispatchData['dispatchCount'] ?? 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(),
                const SizedBox(height: 16),
                _statsCard(
                  notificationCount: notificationCount,
                  seenCount: seenCount,
                  deviceCount: deviceCount,
                  dispatchCount: dispatchCount,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Activated notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (notifications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text('Ingen aktiverte varsler akkurat nå.'),
                  )
                else
                  ...notifications.map(_notificationCard),
                const SizedBox(height: 18),
                const Text(
                  'Push dispatch preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (dispatches.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text('Ingen dispatches akkurat nå.'),
                  )
                else
                  ...dispatches.map(_dispatchCard),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
