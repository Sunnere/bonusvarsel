import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumPaywallSheet extends StatefulWidget {
  final String source;
  final bool elite;
  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;
  final ValueChanged<String>? onPrimary;
  final VoidCallback? onRestore;

  const PremiumPaywallSheet({
    super.key,
    this.source = 'manual',
    this.elite = false,
    this.title,
    this.subtitle,
    this.onClose,
    this.onPrimary,
    this.onRestore,
  });

  @override
  State<PremiumPaywallSheet> createState() => _PremiumPaywallSheetState();
}

class _PremiumPaywallSheetState extends State<PremiumPaywallSheet> {
  String _selectedPlan = 'monthly';

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (widget.elite ? 'Lås opp Elite-fordeler' : 'Lås opp Premium-fordeler');
    final subtitle = widget.subtitle ??
        (widget.elite
            ? 'Elite gir tilgang til flere programmer, mer prioriterte valg og enda flere bonusmuligheter.'
            : 'Premium gir høyere bonusrate, smartere valg og bedre oversikt.');

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF071427),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF162946),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF32598D)),
                    ),
                    child: Icon(
                      widget.elite
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_open_rounded,
                      color: const Color(0xFFFFC44D),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        widget.onClose ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(height: 18),
              _infoCard(
                title: 'Du kan gå glipp av bedre rate',
                body:
                    'Premium gjør det enklere å se hva som faktisk lønner seg før du handler.',
              ),
              const SizedBox(height: 16),
              _planCard(
                title: 'Premium',
                note: 'Typisk +1 500–4 000 poeng i måneden',
                price: '49 kr/mnd',
                selected: _selectedPlan == 'monthly',
                accent: const Color(0xFF8CFF64),
                bullets: const [
                  'Se flere butikker og tilbud',
                  'Få høyere bonusrate',
                  'Lås opp boost og kampanjer',
                  'Velg smartere før du klikker',
                ],
                onTap: () => setState(() => _selectedPlan = 'monthly'),
              ),
              const SizedBox(height: 14),
              _planCard(
                title: 'Elite',
                note: 'Opptil 8 000+ poeng i måneden',
                price: '89 kr/mnd',
                selected: _selectedPlan == 'yearly',
                accent: const Color(0xFFFFC44D),
                bullets: const [
                  'Alt i Premium',
                  'Flere programmer og prioriterte valg',
                  'Enda sterkere verdi og maks synlighet',
                  'Best for deg som vil gå all-in',
                ],
                onTap: () => setState(() => _selectedPlan = 'yearly'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onPrimary?.call(_selectedPlan),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF69AEFF),
                    foregroundColor: const Color(0xFF04152A),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Fortsett til betaling',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final url = Uri.parse('https://bonusvarsel.no');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4AF37),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    '🏆 Kjøp Elite på bonusvarsel.no',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: widget.onRestore,
                  child: const Text(
                    'Gjenopprett kjøp',
                    style: TextStyle(
                      color: Color(0xFF8DC3FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Ingen binding. Avslutt når som helst.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2441),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF67507E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String note,
    required String price,
    required bool selected,
    required Color accent,
    required List<String> bullets,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2546),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? accent : const Color(0xFF3B4E82),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}