#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/onboarding_page.dart"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$FILE" ]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak.${STAMP}"
echo "Backup laget: ${FILE}.bak.${STAMP}"

cat > "$FILE" <<'DART'
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/onboarding_service.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback? onPremiumSelected;
  final String? trumfUrl;
  final String? sasUrl;

  const OnboardingPage({
    super.key,
    required this.onDone,
    this.onPremiumSelected,
    this.trumfUrl,
    this.sasUrl,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _busy = false;

  static const Color _bgTop = Color(0xFF0B1F3A);
  static const Color _bgBottom = Color(0xFF08111E);
  static const Color _card = Color(0xFF11243E);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _green = Color(0xFF22C55E);
  static const Color _blue = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
    OnboardingService.markStarted();
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _next() async {
    if (_index >= 5) {
      await _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goTo(int page) async {
    await _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    await OnboardingService.markCompleted();
    if (!mounted) return;
    widget.onDone();
  }

  Widget _shell({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    Color? accent,
    String? highlight,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final a = accent ?? _gold;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgTop, _bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                    child: const Text('Tilbake'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Hopp over'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: a.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 24,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: a.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: a.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Icon(icon, color: a, size: 30),
                              ),
                              const SizedBox(height: 18),
                              if (highlight != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: a.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: a.withValues(alpha: 0.24),
                                    ),
                                  ),
                                  child: Text(
                                    highlight,
                                    style: TextStyle(
                                      color: a,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.04,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.82),
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              ...children,
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF091423).withValues(alpha: 0.94),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: a,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: onPrimary,
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  if (secondaryLabel != null && onSecondary != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onSecondary,
                        child: Text(
                          secondaryLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _Dots(index: _index, count: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? accent,
  }) {
    final a = accent ?? _gold;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: a, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 13,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageHook(BuildContext context) {
    return _shell(
      context: context,
      icon: Icons.trending_up,
      title: 'Hvor mange bonuspoeng går du glipp av hver måned?',
      subtitle: 'De fleste mister 1 000–8 000 poeng uten å vite det.',
      accent: _gold,
      highlight: 'Bonusvarsel viser deg hvor det faktisk lønner seg',
      children: [
        _bullet(
          icon: Icons.shopping_bag_outlined,
          title: 'Vanlige kjøp kan gi langt mer',
          subtitle: 'Riktig timing, riktig butikk og riktige partnere kan gi stor forskjell.',
        ),
        _bullet(
          icon: Icons.flight_takeoff,
          title: 'Poeng kan bli flyreiser',
          subtitle: 'Små valg i hverdagen kan bygge store reiser over tid.',
        ),
      ],
      primaryLabel: 'Start',
      onPrimary: _next,
    );
  }

  Widget _pageValue(BuildContext context) {
    return _shell(
      context: context,
      icon: Icons.insights_outlined,
      title: 'Vi viser deg hvor du tjener mest',
      subtitle: 'Bonusvarsel samler relevante muligheter på ett sted.',
      accent: _blue,
      highlight: 'SAS + Trumf + kort + kampanjer',
      children: [
        _bullet(
          icon: Icons.flight,
          title: 'SAS EuroBonus',
          subtitle: 'Bygg poeng mot flyreiser og fordeler.',
          accent: _blue,
        ),
        _bullet(
          icon: Icons.local_grocery_store_outlined,
          title: 'Trumf',
          subtitle: 'Enkelt sted å starte med lav terskel.',
          accent: _blue,
        ),
        _bullet(
          icon: Icons.workspace_premium_outlined,
          title: 'Kort og kampanjer',
          subtitle: 'Se hvilke valg som kan gi mest verdi.',
          accent: _blue,
        ),
      ],
      primaryLabel: 'Fortsett',
      onPrimary: _next,
    );
  }

  Widget _pageTrumf(BuildContext context) {
    return _shell(
      context: context,
      icon: Icons.local_grocery_store,
      title: 'Start med Trumf',
      subtitle: 'Tjen bonus på dagligvarer og kjøp – helt gratis.',
      accent: _green,
      highlight: 'Anbefalt start for alle brukere',
      children: [
        _bullet(
          icon: Icons.check_circle_outline,
          title: 'Lav terskel, høy nytte',
          subtitle: 'Enkelt å komme i gang uten å betale noe.',
          accent: _green,
        ),
        _bullet(
          icon: Icons.bolt,
          title: 'Bra første steg',
          subtitle: 'Gir deg et tydelig utgangspunkt før du bygger videre med SAS og Premium.',
          accent: _green,
        ),
      ],
      primaryLabel: 'Bli medlem',
      onPrimary: () async {
        await _openUrl(widget.trumfUrl);
        if (!mounted) return;
        await _next();
      },
      secondaryLabel: 'Hopp over',
      onSecondary: _next,
    );
  }

  Widget _pageSas(BuildContext context) {
    return _shell(
      context: context,
      icon: Icons.flight_takeoff,
      title: 'Koble til SAS EuroBonus',
      subtitle: 'Gjør bonus til reiser, status og mer verdi over tid.',
      accent: _blue,
      highlight: 'Neste naturlige steg etter Trumf',
      children: [
        _bullet(
          icon: Icons.swap_horiz,
          title: 'Bygg videre på bonusen',
          subtitle: 'SAS blir den tydelige broen videre mot flyreiser.',
          accent: _blue,
        ),
        _bullet(
          icon: Icons.travel_explore,
          title: 'Mer relevant for reise',
          subtitle: 'Bedre oversikt over hva som faktisk lønner seg.',
          accent: _blue,
        ),
      ],
      primaryLabel: 'Start med EuroBonus',
      onPrimary: () async {
        await _openUrl(widget.sasUrl);
        if (!mounted) return;
        await _next();
      },
      secondaryLabel: 'Hopp over',
      onSecondary: _next,
    );
  }

  Widget _pageMoment(BuildContext context) {
    return _shell(
      context: context,
      icon: Icons.celebration_outlined,
      title: 'Du er i gang',
      subtitle: 'Nå kan du begynne å samle poeng smartere med bedre oversikt og timing.',
      accent: _gold,
      highlight: 'Små valg kan gi stor forskjell over tid',
      children: [
        _bullet(
          icon: Icons.lightbulb_outline,
          title: 'Du har tatt de viktigste første stegene',
          subtitle: 'Start enkelt først, bygg videre når det gir mening.',
        ),
        _bullet(
          icon: Icons.auto_graph,
          title: 'Neste nivå er optimalisering',
          subtitle: 'Det er her Premium begynner å gi mer verdi.',
        ),
      ],
      primaryLabel: 'Se mine muligheter',
      onPrimary: _next,
    );
  }

  Widget _pagePremium(BuildContext context) {
    return _shell(
      context: context,
      icon: Icons.workspace_premium,
      title: 'Vil du få enda mer ut av dette?',
      subtitle: 'Premium viser deg hvor det faktisk lønner seg å handle, klikke og prioritere.',
      accent: _gold,
      highlight: 'Typisk +1 500–4 000 ekstra poeng per måned',
      children: [
        _bullet(
          icon: Icons.trending_up,
          title: 'Høyeste poengrate',
          subtitle: 'Få bedre oversikt over hvor du kan tjene mest.',
        ),
        _bullet(
          icon: Icons.flash_on_outlined,
          title: 'Boost og kampanjer',
          subtitle: 'Se mer av det som faktisk kan flytte poengsaldoen din.',
        ),
        _bullet(
          icon: Icons.savings_outlined,
          title: 'Mer verdi uten mer friksjon',
          subtitle: 'Du slipper å lete manuelt etter hvilke butikker og tilbud som er best akkurat nå.',
        ),
      ],
      primaryLabel: 'Prøv Premium',
      onPrimary: () async {
        await OnboardingService.markCompleted();
        if (!mounted) return;
        widget.onPremiumSelected?.call();
        widget.onDone();
      },
      secondaryLabel: 'Senere',
      onSecondary: () async {
        await OnboardingService.dismissPremiumForNow();
        await _finish();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _pageHook(context),
      _pageValue(context),
      _pageTrumf(context),
      _pageSas(context),
      _pageMoment(context),
      _pagePremium(context),
    ];

    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (value) {
          if (!mounted) return;
          setState(() => _index = value);
        },
        children: pages,
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int index;
  final int count;

  const _Dots({
    required this.index,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFD4AF37)
                : Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
DART

echo
echo "Skrev ny $FILE"
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter test"
