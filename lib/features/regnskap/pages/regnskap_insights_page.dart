// ============================================================
// Bonusvarsel Regnskap — Insights Page
// lib/features/regnskap/pages/regnskap_insights_page.dart
// ============================================================

import 'package:flutter/material.dart';
import '../services/regnskap_api_service.dart';

class RegnskapInsightsPage extends StatefulWidget {
  const RegnskapInsightsPage({super.key});
  @override
  State<RegnskapInsightsPage> createState() => _RegnskapInsightsPageState();
}

class _RegnskapInsightsPageState extends State<RegnskapInsightsPage> {
  final _api = RegnskapApiService();
  List<RegnskapInsight> _all = [];
  String _filter = 'all';
  bool _loading = true;

  final _filters = [
    ('all',                   'Alle'),
    ('bonus_opportunity',     '⭐ Bonus'),
    ('missing_receipt',       '🧾 Kvitteringer'),
    ('subscription_detected', '🔄 Abonnement'),
    ('cost_increase',         '📈 Kostnader'),
    ('large_purchase',        '💳 Store kjøp'),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getEnrichedInsights();
      setState(() { _all = r.insights; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<RegnskapInsight> get _filtered =>
    _filter == 'all' ? _all : _all.where((i) => i.type == _filter).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070D26),
    appBar: AppBar(
      backgroundColor: const Color(0xFF070D26),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFA3AED0), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('🧠 AI-innsikter',
        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      actions: [
        TextButton(
          onPressed: _load,
          child: const Text('Oppdater', style: TextStyle(color: Color(0xFF868CFF), fontSize: 12)),
        ),
      ],
    ),
    body: Column(
      children: [
        // Export-knapper
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Expanded(child: _exportBtn('📊 Excel', const Color(0xFF01B574), '/export/excel')),
            const SizedBox(width: 8),
            Expanded(child: _exportBtn('📄 PDF', const Color(0xFF3965FF), '/export/pdf')),
          ]),
        ),
        // Filter-tabs
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (key, label) = _filters[i];
              final active = _filter == key;
              return GestureDetector(
                onTap: () => setState(() => _filter = key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF868CFF).withOpacity(0.18) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active ? const Color(0xFF868CFF).withOpacity(0.4) : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Text(label,
                    style: TextStyle(
                      color: active ? const Color(0xFF868CFF) : const Color(0xFFA3AED0),
                      fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    )),
                ),
              );
            },
          ),
        ),
        // Liste
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF868CFF)))
            : _filtered.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _insightCard(_filtered[i]),
                ),
        ),
      ],
    ),
  );

  Widget _exportBtn(String label, Color color, String path) => GestureDetector(
    onTap: () {}, // url_launcher til backend-fiken-ai URL
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Center(child: Text(label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
    ),
  );

  Widget _insightCard(RegnskapInsight ins) {
    const configs = <String, Map<String, Color>>{
      'bonus_opportunity':     {'color': Color(0xFFFFB547), 'bg': Color(0x17FFB547)},
      'missing_receipt':       {'color': Color(0xFFEE5D50), 'bg': Color(0x17EE5D50)},
      'subscription_detected': {'color': Color(0xFF868CFF), 'bg': Color(0x17868CFF)},
      'cost_increase':         {'color': Color(0xFFEE5D50), 'bg': Color(0x17EE5D50)},
      'large_purchase':        {'color': Color(0xFF3965FF), 'bg': Color(0x173965FF)},
    };
    final cfg   = configs[ins.type] ?? {'color': const Color(0xFFA3AED0), 'bg': const Color(0x17A3AED0)};
    final color = cfg['color']!;
    final bg    = cfg['bg']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(ins.icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ins.type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(ins.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(ins.aiExplanation,
                  style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12, height: 1.45)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('score ${ins.score}',
                        style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 10)),
                    ),
                    GestureDetector(
                      onTap: () {
                        _api.dismissInsight(ins.id);
                        setState(() => _all.remove(ins));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Skjul',
                          style: TextStyle(color: Color(0xFFA3AED0), fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('✨', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Ingen innsikter her',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Last opp kontoutskrift for å komme i gang',
          style: TextStyle(color: Color(0xFFA3AED0), fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF868CFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF868CFF).withOpacity(0.3)),
            ),
            child: const Text('← Tilbake til dashbordet',
              style: TextStyle(color: Color(0xFF868CFF), fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    ),
  );
}
