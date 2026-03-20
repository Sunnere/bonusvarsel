import 'package:flutter/material.dart';

import '../models/ad_slot.dart';
import '../services/ad_metrics_service.dart';
import '../services/ad_service.dart';

class AdDebugPage extends StatefulWidget {
  const AdDebugPage({super.key});

  @override
  State<AdDebugPage> createState() => _AdDebugPageState();
}

class _AdDebugPageState extends State<AdDebugPage> {
  final AdMetricsService _metrics = AdMetricsService();

  Future<_DebugData> _load() async {
    final ads = AdService.instance.getCreative();
    final clicks = await _metrics.clicksSnapshot();
    final imps = await _metrics.impressionsSnapshot();

    final rows = <_Row>[];
    for (final ad in ads) {
      final c = clicks[ad.id] ?? 0;
      final i = imps[ad.id] ?? 0;
      final ctr = (i <= 0) ? 0.0 : (c / i);
      rows.add(_Row(ad: ad, clicks: c, imps: i, ctr: ctr));
    }

    rows.sort((a, b) => b.ctr.compareTo(a.ctr));
    return _DebugData(rows: rows);
  }

  Future<void> _reset() async {
    await _metrics.resetAll();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad debug'),
        actions: [
          IconButton(
            tooltip: 'Reset metrics',
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_DebugData>(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          if (data.rows.isEmpty) {
            return const Center(child: Text('No ads found.'));
          }

          return ListView.separated(
            itemCount: data.rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final r = data.rows[idx];
              final a = r.ad;
              return ListTile(
                title: Text(a.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('id: ${a.id}'),
                    Text('tags: ${a.tags.join(", ")}'),
                    const SizedBox(height: 6),
                    Text('imps: ${r.imps}  clicks: ${r.clicks}  ctr: ${r.ctr.toStringAsFixed(3)}'),
                    const SizedBox(height: 6),
                    Text(
                      'sponsored: ${a.isSponsored}  bidCpm: ${a.bidCpm}  guarantee/day: ${a.guaranteePerDay}  priority: ${a.priority}',
                    ),
                  ],
                ),
                trailing: a.isSponsored ? const Icon(Icons.paid) : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _Row {
  final AdSlot ad;
  final int clicks;
  final int imps;
  final double ctr;

  _Row({
    required this.ad,
    required this.clicks,
    required this.imps,
    required this.ctr,
  });
}

class _DebugData {
  final List<_Row> rows;
  _DebugData({required this.rows});
}
