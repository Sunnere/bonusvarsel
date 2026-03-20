import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/feed_item.dart';

class BonusvarselFeedList extends StatefulWidget {
  final int refreshToken;

  const BonusvarselFeedList({
    super.key,
    this.refreshToken = 0,
  });

  @override
  State<BonusvarselFeedList> createState() => _BonusvarselFeedListState();
}

class _BonusvarselFeedListState extends State<BonusvarselFeedList> {
  late Future<List<FeedItem>> _feedFuture;
  late Future<Map<String, dynamic>> _meFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _feedFuture = ApiService.getFeed();
    _meFuture = ApiService.getMe();
  }

  @override
  void didUpdateWidget(covariant BonusvarselFeedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(_load);
    }
  }

  Color _badgeColor(String level) {
    switch (level) {
      case 'boost':
        return Colors.orange;
      case 'premium':
        return Colors.blue;
      case 'elite':
        return const Color(0xFFD4AF37);
      case 'standard':
      default:
        return Colors.grey;
    }
  }

  IconData _badgeIcon(String level) {
    switch (level) {
      case 'boost':
        return Icons.bolt;
      case 'premium':
        return Icons.workspace_premium;
      case 'elite':
        return Icons.emoji_events;
      case 'standard':
      default:
        return Icons.label;
    }
  }

  String _badgeText(String level) {
    switch (level) {
      case 'boost':
        return 'Boost';
      case 'premium':
        return 'Premium';
      case 'elite':
        return 'Elite';
      case 'standard':
      default:
        return 'Standard';
    }
  }

  bool _canSeeLocked(String userTier, FeedItem item) {
    if (!item.lockedForFree) return true;
    if (userTier == 'elite') return true;
    if (userTier == 'premium' && item.level != 'elite') return true;
    return false;
  }

  String _lockedLabel(String level) {
    switch (level) {
      case 'elite':
        return 'Låst for Elite';
      case 'premium':
        return 'Låst for Premium';
      case 'boost':
        return 'Låst boost';
      default:
        return 'Låst';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _feedFuture,
        _meFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Feed error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = snapshot.data![0] as List<FeedItem>;
        final me = snapshot.data![1] as Map<String, dynamic>;
        final userTier = (me['tier'] ?? 'free').toString();

        if (items.isEmpty) {
          return const Center(child: Text('Ingen tilbud funnet'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final badgeColor = _badgeColor(item.level);
            final canSee = _canSeeLocked(userTier, item);

            return ListTile(
              leading: const Icon(Icons.store),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.store,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_badgeIcon(item.level), size: 14, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          _badgeText(item.level),
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                canSee
                    ? '${item.rateText} • ${item.source.toUpperCase()} • ${item.category}'
                    : '🔒 ${_lockedLabel(item.level)} • Oppgrader for å se full rate',
              ),
              trailing: item.campaign
                  ? const Icon(Icons.local_fire_department, color: Colors.orange)
                  : null,
            );
          },
        );
      },
    );
  }
}
