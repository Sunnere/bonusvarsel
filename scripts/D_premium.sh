#!/usr/bin/env bash
set -euo pipefail

# 1) PremiumPage (ny)
cat > lib/pages/premium_page.dart <<'DART'
import 'package:flutter/material.dart';
import '../widgets/premium_card.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool yearly = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final accent = cs.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B1020),
              const Color(0xFF0B1020).withValues(alpha: 0.92),
              const Color(0xFF120B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Bonusvarsel Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Få mer kontroll, flere varsler og bedre oversikt.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
              ),
              const SizedBox(height: 16),

              // Premium hero card
              PremiumCard(
                primary: primary,
                accent: accent,
              ),

              const SizedBox(height: 14),

              // Pricing toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Årsabonnement (anbefalt)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      value: yearly,
                      activeColor: accent,
                      onChanged: (v) => setState(() => yearly = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _FeatureTile(
                icon: Icons.notifications_active_outlined,
                title: 'Varsler på kampanjer og boostede poeng',
                subtitle: 'Få beskjed når det faktisk lønner seg å handle nå.',
              ),
              _FeatureTile(
                icon: Icons.star_outline,
                title: 'Favoritter + smartere sortering',
                subtitle: 'Legg butikker i favoritter og få dem opp først.',
              ),
              _FeatureTile(
                icon: Icons.shield_outlined,
                title: 'Premium-filter (ingen “støy”)',
                subtitle: 'Skjul irrelevante treff og se kun det du trenger.',
              ),
              _FeatureTile(
                icon: Icons.auto_graph_outlined,
                title: 'Historikk og “beste deal”',
                subtitle: 'Se hva som har vært best over tid.',
              ),

              const SizedBox(height: 14),

              // CTA
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kobler på betaling senere 👌')),
                  );
                },
                child: Text(yearly ? 'Start Premium – Årlig' : 'Start Premium – Månedlig'),
              ),

              const SizedBox(height: 10),
              Text(
                'Du kan avslutte når som helst. (Betaling kobles på i neste steg.)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
DART

# 2) PremiumCard (oppgraderer + fjerner withOpacity warnings)
mkdir -p lib/widgets
cat > lib/widgets/premium_card.dart <<'DART'
import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  final Color primary;
  final Color accent;

  const PremiumCard({
    super.key,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.95),
            const Color(0xFF0B1020),
            accent.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 2,
            color: accent.withValues(alpha: 0.18),
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.workspace_premium, color: Colors.white.withValues(alpha: 0.95)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Oppgrader og få mer verdi ut av poengene dine',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Raskere oversikt. Smartere varsler. Mindre støy.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniPill(text: 'Varsler', icon: Icons.notifications_none),
              const SizedBox(width: 8),
              _MiniPill(text: 'Favoritter', icon: Icons.favorite_border),
              const SizedBox(width: 8),
              _MiniPill(text: 'Historikk', icon: Icons.query_stats),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _MiniPill({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
DART

# 3) Koble "Kort" (CardsPage) til PremiumPage (minimalt inngrep)
# Vi bytter innholdet til en wrapper så du ikke trenger å lete i HomePage.
cat > lib/pages/cards_page.dart <<'DART'
import 'package:flutter/material.dart';
import 'premium_page.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PremiumPage();
  }
}
DART

dart format lib/pages/premium_page.dart lib/widgets/premium_card.dart lib/pages/cards_page.dart
echo "✅ D: Premium/paywall lagt til (PremiumPage + PremiumCard) og Kort-tabben viser Premium"
