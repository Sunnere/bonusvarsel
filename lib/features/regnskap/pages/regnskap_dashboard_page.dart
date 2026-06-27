// ============================================================
// Bonusvarsel Regnskap — Dashboard Page
// lib/features/regnskap/pages/regnskap_dashboard_page.dart
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bonusvarsel/theme/app_theme.dart';
import '../services/regnskap_api_service.dart';
import 'regnskap_insights_page.dart';
import 'regnskap_upload_page.dart';

class RegnskapDashboardPage extends StatefulWidget {
  const RegnskapDashboardPage({super.key});

  @override
  State<RegnskapDashboardPage> createState() => _RegnskapDashboardPageState();
}

class _RegnskapDashboardPageState extends State<RegnskapDashboardPage> {
  final _api = RegnskapApiService();

  RegnskapScore?   _score;
  RegnskapSummary? _summary;
  List<RegnskapInsight> _insights = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getScoreWithComment(),
        _api.getSummary(),
        _api.getEnrichedInsights(),
      ]);
      setState(() {
        _score    = results[0] as RegnskapScore;
        _summary  = results[1] as RegnskapSummary;
        _insights = (results[2] as RegnskapInsightResult).insights.take(3).toList();
        _loading  = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D26),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.accentElite,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildGreeting(),
                  const SizedBox(height: 16),
                  if (_loading) _buildSkeleton()
                  else if (_error != null) _buildError()
                  else ...[
                    _buildScoreCard(),
                    const SizedBox(height: 14),
                    _buildStatGrid(),
                    const SizedBox(height: 20),
                    _buildUploadButton(),
                    const SizedBox(height: 20),
                    _buildInsightsSection(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: const Color(0xFF070D26),
    pinned: true,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4318FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text('◆', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    ),
    title: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bonusvarsel', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        Text('Regnskap', style: TextStyle(color: Color(0xFFA3AED0), fontSize: 10)),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Color(0xFFA3AED0)),
        onPressed: () {},
      ),
      IconButton(
        icon: const Icon(Icons.person_outline, color: Color(0xFFA3AED0)),
        onPressed: () {},
      ),
    ],
  );

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'God morgen' : hour < 18 ? 'God dag' : 'God kveld';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting, Roy 👋',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Her er oversikten over økonomien din i dag',
          style: TextStyle(color: Color(0xFFA3AED0), fontSize: 13)),
      ],
    );
  }

  Widget _buildScoreCard() {
    if (_score == null) return const SizedBox.shrink();
    final s = _score!;
    final color = _hexColor(s.color);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2559), Color(0xFF111C44)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF868CFF).withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Score-ring
          SizedBox(
            width: 88, height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(88, 88),
                  painter: _ScoreRingPainter(score: s.score, color: color),
                ),
                Text('${s.score}',
                  style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ØKONOMISCORE',
                  style: TextStyle(color: Color(0xFFA3AED0), fontSize: 10, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(s.label,
                  style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...s.breakdown.take(3).map((b) => _buildBar(b, color)),
                if (s.comment != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF868CFF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF868CFF).withOpacity(0.2)),
                    ),
                    child: Text('💬 ${s.comment}',
                      style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 11, height: 1.5)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(ScoreBreakdown b, Color color) {
    final pct = b.max > 0 ? b.score / b.max : 0.0;
    final barColor = pct >= 0.85 ? const Color(0xFF01B574)
        : pct >= 0.6 ? const Color(0xFFFFB547)
        : const Color(0xFFEE5D50);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(width: 90,
            child: Text(b.category,
              style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 10),
              overflow: TextOverflow.ellipsis)),
          Expanded(
            child: Container(
              height: 4, decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('${b.score}/${b.max}',
            style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final s = _summary;
    final items = [
      ('⭐', 'Poengsaldo',  '128 420', 'EuroBonus-poeng', const Color(0xFFFFB547)),
      ('📈', 'Opptjent',    '+8 560',  'denne måneden',   const Color(0xFF01B574)),
      ('🎯', 'Innsikter',   '${s?.totalInsights ?? "–"}', 'denne måneden', const Color(0xFF868CFF)),
      ('🔥', 'Bonuspoeng',  '${s?.potentialBonusPoints ?? "–"}', 'tilgjengelig', const Color(0xFFEE5D50)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12, runSpacing: 12,
          children: items.map((e) => SizedBox(
            width: w,
            child: _statCard(e.$1, e.$2, e.$3, e.$4, e.$5),
          )).toList(),
        );
      },
    );
  }

  Widget _statCard(String icon, String label, String value, String sub, Color color) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111C44),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700, height: 1.1)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 11)),
      ],
    ),
  );

  Widget _buildUploadButton() => GestureDetector(
    onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const RegnskapUploadPage())),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4318FF).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF868CFF).withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📄', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('Last opp kontoutskrift',
            style: TextStyle(color: Color(0xFF868CFF), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _buildInsightsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🧠 AI-innsikter',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegnskapInsightsPage())),
            child: const Text('Se alle →',
              style: TextStyle(color: Color(0xFF868CFF), fontSize: 13)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_insights.isEmpty)
        _buildEmptyInsights()
      else
        ..._insights.map(_buildInsightCard),
    ],
  );

  Widget _buildInsightCard(RegnskapInsight ins) {
    const configs = {
      'bonus_opportunity':     {'color': Color(0xFFFFB547), 'bg': Color(0x17FFB547)},
      'missing_receipt':       {'color': Color(0xFFEE5D50), 'bg': Color(0x17EE5D50)},
      'subscription_detected': {'color': Color(0xFF868CFF), 'bg': Color(0x17868CFF)},
      'cost_increase':         {'color': Color(0xFFEE5D50), 'bg': Color(0x17EE5D50)},
      'large_purchase':        {'color': Color(0xFF3965FF), 'bg': Color(0x173965FF)},
    };
    final cfg = configs[ins.type] ?? {'color': const Color(0xFFA3AED0), 'bg': const Color(0x17A3AED0)};
    final color = cfg['color'] as Color;
    final bg    = cfg['bg'] as Color;
    final meta  = ins.metadata;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(ins.icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ins.type.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(ins.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(ins.aiExplanation,
                  style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12, height: 1.4)),
                if (ins.type == 'bonus_opportunity' && meta['potential_points'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB547).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFFB547).withOpacity(0.3)),
                    ),
                    child: Text('+${meta['potential_points']} poeng',
                      style: const TextStyle(color: Color(0xFFFFB547), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _api.dismissInsight(ins.id);
              setState(() => _insights.remove(ins));
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, color: Color(0xFFA3AED0), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInsights() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF111C44),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: const Column(
      children: [
        Text('✨', style: TextStyle(fontSize: 32)),
        SizedBox(height: 8),
        Text('Alt ser bra ut!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('Last opp en kontoutskrift for å få AI-innsikter',
          style: TextStyle(color: Color(0xFFA3AED0), fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildSkeleton() => Column(
    children: List.generate(3, (_) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2559),
        borderRadius: BorderRadius.circular(16),
      ),
    )),
  );

  Widget _buildError() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFEE5D50).withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text('Feil: $_error', style: const TextStyle(color: Color(0xFFEE5D50), fontSize: 13)),
  );

  Color _hexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF868CFF);
    }
  }
}

// ---- Score-ring painter ----
class _ScoreRingPainter extends CustomPainter {
  final int score;
  final Color color;
  const _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width - 10) / 2;

    final bg = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, bg);
    final sweep = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2, sweep, false, fg,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.score != score;
}
