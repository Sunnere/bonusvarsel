import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class BonusvarselAlertsPage extends StatefulWidget {
  const BonusvarselAlertsPage({super.key});

  @override
  State<BonusvarselAlertsPage> createState() => _BonusvarselAlertsPageState();
}

class _BonusvarselAlertsPageState extends State<BonusvarselAlertsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String _summary = '-';
  String _lastUpdated = '-';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final health = await ApiService.getHealth();
      final pipeline = health['pipeline'] is Map
          ? Map<String, dynamic>.from(health['pipeline'] as Map)
          : <String, dynamic>{};

      final notifications = pipeline['notifications'] is Map
          ? Map<String, dynamic>.from(pipeline['notifications'] as Map)
          : <String, dynamic>{};

      final itemsRaw = notifications['items'] is List
          ? (notifications['items'] as List)
          : const [];

      final items = itemsRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;

      setState(() {
        _items = items;
        _summary = (pipeline['summary'] ?? '-').toString();
        _lastUpdated = (pipeline['lastUpdated'] ?? '-').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _copyUrl(String url) async {
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lenke kopiert')),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> item, int index) {
    final title = (item['title'] ?? '-').toString();
    final body = (item['body'] ?? '-').toString();
    final rate = (item['rate'] ?? '-').toString();
    final score = (item['score'] ?? '-').toString();
    final commissionType = (item['commissionType'] ?? '-').toString();
    final businessScore = (item['businessScore'] ?? '-').toString();
    final activatedAt = (item['activatedAt'] ?? '-').toString();
    final reason = (item['reason'] ?? '-').toString();
    final url = (item['url'] ?? '').toString();
    final isTop = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              if (isTop)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF34D399)),
                  ),
                  child: const Text(
                    '🏆 TOPPVARSEL',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBF7D0),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF22C55E)),
                ),
                child: const Text(
                  'Aktiv',
                  style: TextStyle(
                    color: Color(0xFF14532D),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Rate', rate),
              _chip('Score', score),
              _chip('Type', commissionType),
              if (businessScore.isNotEmpty && businessScore != '-')
                _chip('Business', businessScore),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reason,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Aktivert: $activatedAt',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 10),
            SelectableText(
              url,
              style: const TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copyUrl(url),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Kopier lenke'),
                ),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Oppdater'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF065F46),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktive bonusvarsler',
            style: TextStyle(
              color: Color(0xFFECFDF5),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Følg de viktigste bonuskampanjene akkurat nå, og få en enkel oversikt over varsler som er valgt ut som mest relevante.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Antall', _items.length.toString()),
              _chip('Sist oppdatert', _lastUpdated),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _summary,
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingen aktive varsler akkurat nå.',
            style: TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Når nye relevante kampanjer blir valgt, dukker de opp her automatisk.',
            style: TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Oppdater varsler'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        'Kunne ikke hente varsler: $_error',
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Varsler'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _heroCard(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorState()
            else if (_items.isEmpty)
              _emptyState()
            else
              ..._items.asMap().entries.map(
                    (entry) => _notificationCard(entry.value, entry.key),
                  ),
          ],
        ),
      ),
    );
  }
}
