import 'package:flutter/material.dart';

import '../models/card_catalog.dart';
import '../services/user_state.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  final TextEditingController _amountCtrl = TextEditingController(text: '5000');

  final List<String> _programs = const [
    'SAS EuroBonus',
    'CashPoints',
    'Flying Blue',
  ];

  String _selectedProgram = 'SAS EuroBonus';

  String? _selectedCardId;
  int _cardRatePer100 = 0; // poeng per 100 NOK

  @override
  void initState() {
    super.initState();
    _loadSelectedCard();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedCard() async {
    // Henter det brukeren har valgt i "Kort"-siden
    final id = await UserState.getSelectedCardId();
    final savedRate = await UserState.getSelectedCardRatePer100(); // double?

    if (!mounted) return;

    // Prioritet:
    // 1) CardCatalog (hvis id finnes der)
    // 2) lagret rate fra prefs
    // 3) 0
    final catalogRate = CardCatalog.rateFor(id);
    final rateInt = (catalogRate != 0)
        ? catalogRate
        : ((savedRate ?? 0).round()); // <-- fikser num/int-greia

    setState(() {
      _selectedCardId = id;
      _cardRatePer100 = rateInt;
    });
  }

  double _amount() {
    final raw =
        _amountCtrl.text.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(raw) ?? 0.0;
  }

  int _estimatePoints(double amountNok) {
    const basePer100 = 5.0; // placeholder base-rate
    final base = (amountNok / 100.0) * basePer100;
    final card = (amountNok / 100.0) * _cardRatePer100;
    return (base + card).round();
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount();
    final estPoints = _estimatePoints(amount);

    final cardName = CardCatalog.nameFor(_selectedCardId);
    final cardLabel = (_selectedCardId == null)
        ? 'Gå til "Kort" og velg et kort'
        : 'Valgt kort: $cardName • $_cardRatePer100 poeng per 100 kr';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reise'),
        actions: [
          IconButton(
            tooltip: 'Oppdater valgt kort',
            onPressed: _loadSelectedCard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedProgram,
                decoration: const InputDecoration(
                  labelText: 'Bonusprogram',
                  border: OutlineInputBorder(),
                ),
                items: _programs
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedProgram = v);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Reisebeløp (NOK)',
                  hintText: 'f.eks 5000',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Text(
                cardLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'Estimert opptjening',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$estPoints poeng',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
