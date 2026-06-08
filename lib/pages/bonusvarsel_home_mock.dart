// Bonusvarsel Home Mock (First-class UI)
// Drop-in page you can navigate to from anywhere.
//
// Usage (quick test):
//   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BonusvarselHomeMock()));
//
// Or set as home in your MaterialApp temporarily:
//   home: const BonusvarselHomeMock(),
//
// Notes:
// - No external deps.
// - Uses SliverAppBar + hero card + tiles + last transactions + floating QR button + bottom nav.
// - Styles tuned to feel like SAS/Trumf.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BonusvarselHomeMock extends StatefulWidget {
  const BonusvarselHomeMock({super.key});

  @override
  State<BonusvarselHomeMock> createState() => _BonusvarselHomeMockState();
}

class _BonusvarselHomeMockState extends State<BonusvarselHomeMock> {
  int _navIndex = 0;

  // Mock state
  final String _name = 'Roy Røtvold';
  final int _bonusPoints = 30269;
  final int _trumfSaldoKr = 38;

  final List<_Txn> _txns = const [
    _Txn(
      brand: 'KIWI',
      title: 'KIWI Trosterud',
      dateText: '04. mars',
      amountText: '115 kr',
      earnedText: '+12,32 kr',
      isLocked: false,
    ),
    _Txn(
      brand: 'SAS',
      title: 'EuroBonus Shopping',
      dateText: '03. mars',
      amountText: '—',
      earnedText: '+450 poeng',
      isLocked: true, // show premium blur overlay
    ),
    _Txn(
      brand: 'Trumf',
      title: 'Trumf Overføring',
      dateText: '01. mars',
      amountText: '—',
      earnedText: '+25 kr',
      isLocked: false,
    ),
  ];

  // Theme-ish tokens
  static const _brandBlueA = Color(0xFF2F80ED);
  static const _brandBlueB = Color(0xFF0B4AA2);
  static const _bg = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildHeaderSliver(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroCard(context, cs),
                  const SizedBox(height: 14),
                  _dotsIndicator(),
                  const SizedBox(height: 18),
                  _sectionTitle('Siste handel'),
                  const SizedBox(height: 10),
                  _txnCard(context, _txns.first),
                  const SizedBox(height: 14),
                  _twoTilesRow(context),
                  const SizedBox(height: 18),
                  _sectionTitle('Aktivitet'),
                  const SizedBox(height: 10),
                  _feedList(context),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating QR-like pill button (Trumf-kort feel)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _floatingQrPill(context),

      bottomNavigationBar: _bottomNav(context),
    );
  }

  SliverAppBar _buildHeaderSliver(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 170,
      backgroundColor: _brandBlueA,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_brandBlueA, _brandBlueB],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFBFE3FF),
                  child: Text(
                    'RR',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.surface,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_greeting()} • Trumf-saldo $_trumfSaldoKr kr',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  tooltip: 'Varsler',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  tooltip: 'Meny',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = TimeOfDay.now().hour;
    if (h < 12) return 'God morgen';
    if (h < 18) return 'God dag';
    return 'God kveld';
  }

  
  Widget _heroCard(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2F80ED),
            Color(0xFF0B4AA2),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0,12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Din bonus",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height:6),

          Text(
            "$_trumfSaldoKr kr",
            style: const TextStyle(
              color: AppTheme.surface,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),

          const SizedBox(height:14),

          Row(
            children: [

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical:14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Bruk bonus",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width:10),

              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  color: AppTheme.surface,
                ),
              )

            ],
          ),

          const SizedBox(height:18),

          const Text(
            "EuroBonus saldo",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height:4),

          Text(
            "$_bonusPoints poeng",
            style: const TextStyle(
              color: AppTheme.surface,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),

        ],
      ),
    );
  }



  Widget _dotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(active: true),
        const SizedBox(width: 8),
        _dot(active: false),
        const SizedBox(width: 8),
        _dot(active: false),
      ],
    );
  }

  Widget _dot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        color: active ? _brandBlueA : Colors.black.withValues(alpha: 0.20),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _txnCard(BuildContext context, _Txn t) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _brandBadge(t.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  t.dateText,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.amountText,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t.earnedText,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.35)),
        ],
      ),
    );

    if (!t.isLocked) return card;

    return Stack(
      children: [
        card,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.white.withValues(alpha: 0.25),
                padding: const EdgeInsets.all(14),
                alignment: Alignment.center,
                child: _lockedOverlay(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lockedOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.textMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, color: AppTheme.surface, size: 18),
          SizedBox(width: 8),
          Text(
            'Oppgrader for detaljer',
            style: TextStyle(color: AppTheme.surface, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _brandBadge(String brand) {
    final bg = switch (brand) {
      'KIWI' => const Color(0xFFE8F7EE),
      'SAS' => const Color(0xFFEAF1FF),
      'Trumf' => const Color(0xFFFFF2E2),
      _ => Colors.black.withValues(alpha: 0.04),
    };

    final fg = switch (brand) {
      'KIWI' => const Color(0xFF0B7A2A),
      'SAS' => _brandBlueB,
      'Trumf' => const Color(0xFFB25B00),
      _ => Colors.black87,
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        brand,
        style: TextStyle(fontWeight: FontWeight.w900, color: fg),
      ),
    );
  }

  Widget _twoTilesRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _tile(
            title: 'Historikk',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFFFD9D9),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tile(
            title: 'Din sparing',
            icon: Icons.savings_rounded,
            color: const Color(0xFFFFE9C9),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: Colors.black.withValues(alpha: 0.85)),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedList(BuildContext context) {
    return ListView.separated(
      itemCount: _txns.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _txnCard(context, _txns[i]),
    );
  }

  Widget _floatingQrPill(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandBlueA.withValues(alpha: 0.90),
          foregroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text(
          'Trumf-kort',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _brandBlueA,
      unselectedItemColor: Colors.black.withValues(alpha: 0.45),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Hjem'),
        BottomNavigationBarItem(icon: Icon(Icons.percent_rounded), label: 'Fordeler'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
      ],
    );
  }

}

class _Txn {
  final String brand;
  final String title;
  final String dateText;
  final String amountText;
  final String earnedText;
  final bool isLocked;

  const _Txn({
    required this.brand,
    required this.title,
    required this.dateText,
    required this.amountText,
    required this.earnedText,
    required this.isLocked,
  });
}
