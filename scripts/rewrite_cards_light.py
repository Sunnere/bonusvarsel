#!/usr/bin/env python3
import os

path = os.path.expanduser('~/bonusvarsel/lib/pages/cards_page.dart')

# Backup
with open(path, 'r') as f:
    original = f.read()
with open(path + '.bak', 'w') as f:
    f.write(original)
print("✅ Backup lagret:", path + '.bak')

dart = '''import 'package:flutter/material.dart';
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

  static const _cards = [
    _CardInfo(
      id: 'sas_amex',
      name: 'SAS EuroBonus American Express',
      network: 'Amex',
      ratePer100: 20,
      accentColor: Color(0xFF00447C),
      bgColor: Color(0xFFEFF6FF),
      borderColor: Color(0xFFBFDBFE),
      description: 'Beste SAS-kort. 20 poeng per 100 kr på alle kjøp. Søk direkte hos American Express Norge.',
      url: 'https://www.americanexpress.com/no/',
      badge: 'Mest poeng',
      emoji: '✈️',
    ),
    _CardInfo(
      id: 'sas_mc',
      name: 'SAS EuroBonus Mastercard',
      network: 'Mastercard',
      ratePer100: 15,
      accentColor: Color(0xFF1e40af),
      bgColor: Color(0xFFEFF6FF),
      borderColor: Color(0xFFBFDBFE),
      description: 'SAS EuroBonus Mastercard via DNB. Gå til Mine kort i DNB-appen → Mastercard → Oppgrader → legg inn EuroBonus-nummer.',
      url: 'https://saseurobonusmastercard.no/kortene/mastercard/',
      badge: 'Populær',
      emoji: '🔵',
    ),
    _CardInfo(
      id: 'sas_visa',
      name: 'SAS EuroBonus Visa',
      network: 'Visa',
      ratePer100: 10,
      accentColor: Color(0xFF1D4ED8),
      bgColor: Color(0xFFEFF6FF),
      borderColor: Color(0xFFBFDBFE),
      description: 'SAS EuroBonus Visa via Lunar. Last ned Lunar-appen og søk om SAS EuroBonus Visa direkte der.',
      url: 'https://www.lunar.app/en/personal/sas-eurobonus',
      badge: null,
      emoji: '💳',
    ),
    _CardInfo(
      id: 'trumf_visa',
      name: 'Trumf Visa',
      network: 'Visa',
      ratePer100: 10,
      accentColor: Color(0xFF15803D),
      bgColor: Color(0xFFECFDF5),
      borderColor: Color(0xFFBBF7D0),
      description: 'Trumf Visa via Trumf Pay. Legg til Visa-kortet ditt i Trumf-appen under Trumf Pay for å koble opptjening.',
      url: 'https://www.trumf.no/trumf-kredittkort/trumf-kredittkort-i-trumf-pay',
      badge: 'Trumf',
      emoji: '🟢',
    ),
    _CardInfo(
      id: 'trumf_mc',
      name: 'Trumf Mastercard',
      network: 'Mastercard',
      ratePer100: 8,
      accentColor: Color(0xFF166534),
      bgColor: Color(0xFFECFDF5),
      borderColor: Color(0xFFBBF7D0),
      description: 'Trumf sitt eget Mastercard. Søk på trumf.no. 8 poeng per 100 kr på alle kjøp. Best kombinert med Trumf-medlemskap.',
      url: 'https://www.trumf.no',
      badge: null,
      emoji: '🌿',
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
        content: Text(CardCatalog.nameFor(id) + \' valgt som aktivt kort\'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(\'Kunne ikke åpne lenken\')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _cards.where((c) => c.id == _selectedCardId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          \'Kort\',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero-boks
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      color: Color(0xFF1e40af), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        \'Velg bonuskort\',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected != null
                            ? \'Aktivt: \${selected.name}\'
                            : \'Ingen kort valgt ennå\',
                        style: TextStyle(
                          color: selected != null
                              ? selected.accentColor
                              : Colors.black45,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF15803D), size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SAS-seksjon
          _sectionHeader(\'✈️  SAS EuroBonus\', const Color(0xFF1e40af)),
          const SizedBox(height: 8),
          ..._cards
              .where((c) => c.id.startsWith(\'sas\'))
              .map((card) => _CardTile(
                    card: card,
                    isSelected: _selectedCardId == card.id,
                    onSelect: () => _selectCard(card.id, card.ratePer100),
                    onOpenUrl: () => _openUrl(card.url),
                  )),
          const SizedBox(height: 8),

          // Trumf-seksjon
          _sectionHeader(\'🟢  Trumf\', const Color(0xFF15803D)),
          const SizedBox(height: 8),
          ..._cards
              .where((c) => c.id.startsWith(\'trumf\'))
              .map((card) => _CardTile(
                    card: card,
                    isSelected: _selectedCardId == card.id,
                    onSelect: () => _selectCard(card.id, card.ratePer100),
                    onOpenUrl: () => _openUrl(card.url),
                  )),
          const SizedBox(height: 12),

          // Info-boks
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  \'ℹ️  Slik fungerer kortvalget\',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  \'• Valgt kort brukes til poengberegning på Reise-siden\\n\'
                  \'• Poeng per 100 kr er basert på standard opptjeningsrate\\n\'
                  \'• Faktisk opptjening avhenger av butikk og tilbud\\n\'
                  \'• Trykk "Se kort" for å søke om eller lese mer\',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.55,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
      ],
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? card.bgColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? card.accentColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ikon-sirkel
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: card.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: card.borderColor),
                    ),
                    child: Center(
                      child: Text(card.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
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
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (card.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: card.bgColor,
                                  borderRadius: BorderRadius.circular(999),
                                  border:
                                      Border.all(color: card.borderColor),
                                ),
                                child: Text(
                                  card.badge!,
                                  style: TextStyle(
                                    color: card.accentColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          \'\${card.network}  •  \${card.ratePer100} poeng/100 kr\',
                          style: TextStyle(
                            color: card.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? card.accentColor : Colors.black26,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                card.description,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isSelected
                            ? card.accentColor
                            : const Color(0xFFF1F5F9),
                        foregroundColor: isSelected
                            ? Colors.white
                            : Colors.black87,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onSelect,
                      child: Text(
                        isSelected ? \'✓ Aktivt kort\' : \'Velg dette kortet\',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: card.accentColor,
                      side: BorderSide(color: card.borderColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onOpenUrl,
                    child: const Text(\'Se kort\',
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
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final String description;
  final String url;
  final String? badge;
  final String emoji;

  const _CardInfo({
    required this.id,
    required this.name,
    required this.network,
    required this.ratePer100,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.description,
    required this.url,
    this.badge,
    required this.emoji,
  });
}
'''

with open(path, 'w') as f:
    f.write(dart)

print("✅ cards_page.dart skrevet om til lys design")
print("   - Hvit/lys bakgrunn (0xFFF8FAFC)")
print("   - SAS-seksjon: blå aksenter")
print("   - Trumf-seksjon: grønne aksenter")
print("   - Emoji-ikoner i stedet for mørke bokser")
print("   - Seksjonsoverskrifter med divider")
