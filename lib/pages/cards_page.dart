import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/login_page.dart';
import '../models/card_catalog.dart';
import '../services/user_state.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  String? _selectedCardId;

  // Kortdata med logo-farge, beskrivelse og URL
  static const _cards = [
    _CardInfo(
      id: 'sas_amex',
      name: 'SAS EuroBonus American Express',
      network: 'Amex',
      ratePer100: 20,
      color: Color(0xFF00447C),
      icon: Icons.credit_card,
      description: 'Beste SAS-kort. 20 poeng per 100 kr på alle kjøp. Søk direkte hos American Express Norge.',
      url: 'https://www.americanexpress.com/no/',
      badge: 'Mest poeng',
    ),
    _CardInfo(
      id: 'sas_mc',
      name: 'SAS EuroBonus Mastercard',
      network: 'Mastercard',
      ratePer100: 15,
      color: Color(0xFF1A1A2E),
      icon: Icons.credit_card,
      description: 'SAS EuroBonus Mastercard via DNB. Gå til Mine kort i DNB-appen → trykk Mastercard → Oppgrader → legg inn EuroBonus-nummer. 15 poeng per 100 kr.',
      url: 'https://saseurobonusmastercard.no/kortene/mastercard/',
      badge: 'Populær',
    ),
    _CardInfo(
      id: 'sas_visa',
      name: 'SAS EuroBonus Visa',
      network: 'Visa',
      ratePer100: 10,
      color: Color(0xFF1A3C6E),
      icon: Icons.credit_card,
      description: 'SAS EuroBonus Visa via Lunar. Last ned Lunar-appen og søk om SAS EuroBonus Visa direkte der. 10 poeng per 100 kr.',
      url: 'https://www.lunar.app/en/personal/sas-eurobonus',
      badge: null,
    ),
    _CardInfo(
      id: 'trumf_visa',
      name: 'Trumf Visa',
      network: 'Visa',
      ratePer100: 10,
      color: Color(0xFF6B2D8B),
      icon: Icons.credit_card,
      description: 'Trumf Visa via Trumf Pay. Legg til Visa-kortet ditt i Trumf-appen under Trumf Pay for å koble opptjening. 10 poeng per 100 kr.',
      url: 'https://www.trumf.no/trumf-kredittkort/trumf-kredittkort-i-trumf-pay',
      badge: 'Trumf',
    ),
    _CardInfo(
      id: 'trumf_mc',
      name: 'Trumf Mastercard',
      network: 'Mastercard',
      ratePer100: 8,
      color: Color(0xFF4A1F6B),
      icon: Icons.credit_card,
      description: 'Trumf sitt eget Mastercard. Søk på trumf.no. 8 poeng per 100 kr på alle kjøp. Best kombinert med Trumf-medlemskap.',
      url: 'https://www.trumf.no',
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final id = await UserState.getSelectedCardId();
    if (!mounted) return;
    setState(() => _selectedCardId = id);
  }

  Future<void> _selectCard(String id, int rate) async {
    // Krev innlogging for å velge kort
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onSuccess: () async {
              await UserState.setSelectedCard(id, rate.toDouble());
              if (!mounted) return;
              setState(() => _selectedCardId = id);
            },
          ),
        ),
      );
      return;
    }

    await UserState.setSelectedCard(id, rate.toDouble());
    if (!mounted) return;
    setState(() => _selectedCardId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(CardCatalog.nameFor(id) + ' valgt som aktivt kort'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke åpne lenken')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _cards.where((c) => c.id == _selectedCardId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kort'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Velg ditt bonuskort',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Valgt kort brukes til å beregne poeng på Reise og Shopping.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected.color.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected.color.withValues(alpha: 0.60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Aktivt: ${selected.name}  •  ${selected.ratePer100} p/100 kr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tilgjengelige kort',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ..._cards.map((card) => _CardTile(
                card: card,
                isSelected: _selectedCardId == card.id,
                onSelect: () => _selectCard(card.id, card.ratePer100),
                onOpenUrl: () => _openUrl(card.url),
              )),
          const SizedBox(height: 20),
          // Info-boks
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slik fungerer kortvalget',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Valgt kort brukes til poengberegning på Reise-siden\n'
                  '• Poeng per 100 kr er basert på standard opptjeningsrate\n'
                  '• Faktisk opptjening avhenger av butikk og tilbud\n'
                  '• Trykk "Se kort" for å søke om eller lese mer om kortet',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 13,
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

class _CardTile extends StatelessWidget {
  final _CardInfo card;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onOpenUrl;

  const _CardTile({
    required this.card,
    required this.isSelected,
    required this.onSelect,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? card.color
              : const Color(0xFF334155),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? card.color.withValues(alpha: 0.12)
            : const Color(0xFF0F172A),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: card.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(card.icon,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                card.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (card.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: card.color.withValues(alpha: 0.30),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color:
                                          card.color.withValues(alpha: 0.60)),
                                ),
                                child: Text(
                                  card.badge!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${card.network}  •  ${card.ratePer100} poeng per 100 kr',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? card.color : Colors.white38,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                card.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isSelected
                            ? card.color
                            : const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onSelect,
                      child: Text(
                        isSelected ? '✓ Aktivt kort' : 'Velg dette kortet',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onOpenUrl,
                    child: const Text('Se kort',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardInfo {
  final String id;
  final String name;
  final String network;
  final int ratePer100;
  final Color color;
  final IconData icon;
  final String description;
  final String url;
  final String? badge;

  const _CardInfo({
    required this.id,
    required this.name,
    required this.network,
    required this.ratePer100,
    required this.color,
    required this.icon,
    required this.description,
    required this.url,
    this.badge,
  });
}
