import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../services/api_service.dart';

class BonusvarselPaywallPage extends StatefulWidget {
  const BonusvarselPaywallPage({super.key});

  @override
  State<BonusvarselPaywallPage> createState() => _BonusvarselPaywallPageState();
}

class _BonusvarselPaywallPageState extends State<BonusvarselPaywallPage> {
  String _tier = 'free';
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _tier = (me['tier'] ?? 'free').toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tier = 'free';
        _loading = false;
      });
    }
  }

  Future<void> _setTier(String tier) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ApiService.setDevTier(tier);
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _tier = (me['tier'] ?? tier).toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tier satt til ${tier.toUpperCase()}')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke oppdatere tier: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  int _tierRank(String tier) {
    switch (tier) {
      case 'elite':
        return 3;
      case 'premium':
        return 2;
      case 'free':
      default:
        return 1;
    }
  }

  bool _isCurrent(String tier) => _tier == tier;

  bool _isDowngradeOrSame(String tier) => _tierRank(tier) <= _tierRank(_tier);

  Color _accent(String tier) {
    switch (tier) {
      case 'elite':
        return const Color(0xFFD4AF37);
      case 'premium':
        return const Color(0xFF2F80ED);
      default:
        return Colors.grey;
    }
  }

  IconData _icon(String tier) {
    switch (tier) {
      case 'elite':
        return Icons.emoji_events;
      case 'premium':
        return Icons.workspace_premium;
      default:
        return Icons.lock_outline;
    }
  }

  String _price(String tier) {
    switch (tier) {
      case 'elite':
        return '149 kr / mnd';
      case 'premium':
        return '79 kr / mnd';
      default:
        return '0 kr';
    }
  }

  List<String> _features(String tier) {
    switch (tier) {
      case 'elite':
        return const [
          'Alt i Premium',
          'Se alle elite-boosts',
          'Maks synlighet på skjulte rates',
          'Tidlig tilgang til nye kampanjer',
          'Beste oppgraderingsverdi',
        ];
      case 'premium':
        return const [
          'Se premium-tilbud',
          'Lås opp boost-rates',
          'Bedre deal-oversikt',
          'Raskere vei til poengfunn',
        ];
      case 'free':
      default:
        return const [
          'Standard feed',
          'Begrenset innsyn i boost',
          'Premium og Elite delvis låst',
        ];
    }
  }

  String _ctaLabel(String tier) {
    if (_isCurrent(tier)) {
      return '${tier[0].toUpperCase()}${tier.substring(1)} aktiv';
    }
    if (_isDowngradeOrSame(tier)) {
      return 'Du har allerede mer';
    }
    return 'Oppgrader til ${tier[0].toUpperCase()}${tier.substring(1)}';
  }

  Widget _planCard({
    required String tier,
    required String title,
    required String subtitle,
    required bool highlighted,
  }) {
    final color = _accent(tier);
    final current = _isCurrent(tier);
    final downgradeOrSame = _isDowngradeOrSame(tier);
    final canUpgrade = !downgradeOrSame && !current;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.surface,
        border: Border.all(
          color: current
              ? Colors.green.withValues(alpha: 0.45)
              : highlighted
                  ? color.withValues(alpha: 0.55)
                  : Colors.black12,
          width: current || highlighted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted || current)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: current
                    ? Colors.green.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.12),
              ),
              child: Text(
                current
                    ? 'Nåværende plan'
                    : tier == 'elite'
                        ? 'Mest verdi'
                        : 'Anbefalt',
                style: TextStyle(
                  color: current ? Colors.green : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_icon(tier), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (current)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.green.withValues(alpha: 0.12),
                  ),
                  child: const Text(
                    'Aktiv',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.72),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _price(tier),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: tier == 'free' ? Colors.black : color,
            ),
          ),
          const SizedBox(height: 12),
          ..._features(tier).map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: tier == 'free'
                ? OutlinedButton(
                    onPressed: current || _busy ? null : () => _setTier('free'),
                    child: Text(_ctaLabel(tier)),
                  )
                : FilledButton(
                    onPressed: canUpgrade && !_busy ? () => _setTier(tier) : null,
                    child: Text(_ctaLabel(tier)),
                  ),
          ),
          if (downgradeOrSame && !current)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Du har allerede denne planen eller høyere.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _comparisonRow(
    String feature,
    bool free,
    bool premium,
    bool elite,
  ) {
    Widget cell(bool value, Color color) {
      return Icon(
        value ? Icons.check : Icons.close,
        color: value ? color : Colors.black38,
        size: 18,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Center(child: cell(free, Colors.grey))),
          Expanded(child: Center(child: cell(premium, const Color(0xFF2F80ED)))),
          Expanded(child: Center(child: cell(elite, const Color(0xFFD4AF37)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oppgrader Bonusvarsel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1F4D),
                  Color(0xFF2F80ED),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lås opp flere poengfunn',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.surface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Se skjulte boosts, premium-rates og elite-tilbud før andre.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    'Nåværende tier: ${_tier.toUpperCase()}',
                    style: const TextStyle(
                      color: AppTheme.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _planCard(
            tier: 'free',
            title: 'Free',
            subtitle: 'For deg som bare vil se standardnivået.',
            highlighted: false,
          ),
          _planCard(
            tier: 'premium',
            title: 'Premium',
            subtitle: 'For deg som vil se boosts og premium-rates.',
            highlighted: true,
          ),
          _planCard(
            tier: 'elite',
            title: 'Elite',
            subtitle: 'For deg som vil ha full tilgang til alle muligheter.',
            highlighted: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sammenligning',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(flex: 5, child: SizedBox()),
                    Expanded(child: Center(child: Text('Free'))),
                    Expanded(child: Center(child: Text('Premium'))),
                    Expanded(child: Center(child: Text('Elite'))),
                  ],
                ),
                const SizedBox(height: 8),
                _comparisonRow('Standard feed', true, true, true),
                _comparisonRow('Boost-rates', false, true, true),
                _comparisonRow('Premium-tilbud', false, true, true),
                _comparisonRow('Elite-tilbud', false, false, true),
                _comparisonRow('Tidlig tilgang', false, false, true),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
