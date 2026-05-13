import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/card_catalog.dart';
import '../services/user_state.dart';
import '../services/entitlement_service.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  // Reiseprofil
  final _destinationCtrl = TextEditingController(text: 'Bangkok');
  int _adults = 2;
  int _children = 2;

  // Valg av reiseelementer
  bool _includeFlight = true;
  bool _includeHotel = false;
  bool _includeCar = false;

  // Priser
  final _flightCtrl = TextEditingController(text: '');
  final _hotelCtrl = TextEditingController(text: '');
  final _carCtrl = TextEditingController(text: '');
  int _hotelNights = 7;
  int _carDays = 7;

  // Bonusprogram og kort
  String _selectedProgram = 'SAS EuroBonus';
  final List<String> _programs = const ['SAS EuroBonus', 'CashPoints', 'Flying Blue'];
  String? _selectedCardId;
  int _cardRatePer100 = 0;

  // Poengstatus
  final _sasPointsCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadSelectedCard();
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _flightCtrl.dispose();
    _hotelCtrl.dispose();
    _carCtrl.dispose();
    _sasPointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedCard() async {
    final id = await UserState.getSelectedCardId();
    final savedRate = await UserState.getSelectedCardRatePer100();
    if (!mounted) return;
    final catalogRate = CardCatalog.rateFor(id);
    final rateInt = catalogRate != 0 ? catalogRate : ((savedRate ?? 0).round());
    setState(() {
      _selectedCardId = id;
      _cardRatePer100 = rateInt;
    });
  }

  int get _totalAmount {
    int total = 0;
    if (_includeFlight) total += int.tryParse(_flightCtrl.text.replaceAll(' ', '')) ?? 0;
    if (_includeHotel) total += int.tryParse(_hotelCtrl.text.replaceAll(' ', '')) ?? 0;
    if (_includeCar) total += int.tryParse(_carCtrl.text.replaceAll(' ', '')) ?? 0;
    return total;
  }

  int get _estimatedPoints {
    if (_cardRatePer100 == 0) return 0;
    return (_totalAmount * _cardRatePer100 / 100).round();
  }

  int get _currentPoints => int.tryParse(_sasPointsCtrl.text.replaceAll(' ', '')) ?? 0;
  int get _pointsAfter => _currentPoints + _estimatedPoints;

  bool get _isPremium => EntitlementService.instance.isPremium;
  bool get _isElite => EntitlementService.instance.isElite;

  String get _destination => _destinationCtrl.text.trim().isEmpty ? 'reisemålet' : _destinationCtrl.text.trim();

  String _formatNum(int v) {
    final s = v.toString();
    final chunks = <String>[];
    for (int i = s.length; i > 0; i -= 3) {
      chunks.insert(0, s.substring(i - 3 < 0 ? 0 : i - 3, i));
    }
    return chunks.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Hero ──
            _heroCard(theme),
            const SizedBox(height: 16),

            // ── Destinasjoner ──
            _destinationsSection(),
            const SizedBox(height: 12),

            // ── Bonusprogram ──
            _sectionCard(
              theme,
              title: 'Bonusprogram',
              child: DropdownButtonFormField<String>(
                value: _selectedProgram,
                decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                items: _programs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _selectedProgram = v ?? _selectedProgram),
              ),
            ),
            const SizedBox(height: 12),

            // ── Reiseprofil ──
            _sectionCard(
              theme,
              title: 'Reiseprofil',
              subtitle: 'Velg reisemål og antall personer',
              child: Column(
                children: [
                  TextField(
                    controller: _destinationCtrl,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(
                      labelText: 'Reisemål',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight_takeoff),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _counterWidget('Voksne', _adults,
                        onMinus: _adults > 1 ? () => setState(() => _adults--) : null,
                        onPlus: () => setState(() => _adults++)),
                      const SizedBox(height: 8),
                      _counterWidget('Barn (under 12)', _children,
                        onMinus: _children > 0 ? () => setState(() => _children--) : null,
                        onPlus: () => setState(() => _children++)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Reiseelementer ──
            _sectionCard(
              theme,
              title: 'Hva trenger du?',
              subtitle: 'Velg ett eller flere – vi regner ut totalen',
              child: Column(
                children: [
                  _travelElementToggle(
                    icon: Icons.flight,
                    label: 'Fly',
                    selected: _includeFlight,
                    onToggle: (v) => setState(() => _includeFlight = v),
                    child: _includeFlight ? Column(
                      children: [
                        const SizedBox(height: 12),
                        TextField(
                          controller: _flightCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Flypris totalt (NOK)',
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'f.eks. ${_formatNum(35000 * (_adults + _children))}',
                            border: const OutlineInputBorder(),
                            prefixText: 'kr ',
                          ),
                        ),
                      ],
                    ) : null,
                  ),
                  const SizedBox(height: 8),
                  _travelElementToggle(
                    icon: Icons.hotel,
                    label: 'Hotell',
                    selected: _includeHotel,
                    onToggle: (v) => setState(() => _includeHotel = v),
                    child: _includeHotel ? Column(
                      children: [
                        const SizedBox(height: 12),
                        TextField(
                          controller: _hotelCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Hotellpris totalt (NOK)',
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'f.eks. 10 000',
                            border: OutlineInputBorder(),
                            prefixText: 'kr ',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Text('Antall netter:'),
                          const SizedBox(width: 12),
                          _counterWidget('', _hotelNights,
                            onMinus: _hotelNights > 1 ? () => setState(() => _hotelNights--) : null,
                            onPlus: () => setState(() => _hotelNights++)),
                        ]),
                      ],
                    ) : null,
                  ),
                  const SizedBox(height: 8),
                  _travelElementToggle(
                    icon: Icons.directions_car,
                    label: 'Leiebil',
                    selected: _includeCar,
                    onToggle: (v) => setState(() => _includeCar = v),
                    child: _includeCar ? Column(
                      children: [
                        const SizedBox(height: 12),
                        TextField(
                          controller: _carCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Leiebilpris totalt (NOK)',
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'f.eks. 5 000',
                            border: OutlineInputBorder(),
                            prefixText: 'kr ',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Text('Antall dager:'),
                          const SizedBox(width: 12),
                          _counterWidget('', _carDays,
                            onMinus: _carDays > 1 ? () => setState(() => _carDays--) : null,
                            onPlus: () => setState(() => _carDays++)),
                        ]),
                      ],
                    ) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Totalsum ──
            if (_totalAmount > 0) ...[
              _totalSummaryCard(theme),
              const SizedBox(height: 12),
            ],

            // ── Poengstatus ──
            _sectionCard(
              theme,
              title: 'Din poengstatus',
              subtitle: 'Legg inn poengene du har nå',
              child: Column(
                children: [
                  TextField(
                    controller: _sasPointsCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nåværende SAS EuroBonus-poeng',
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Skriv inn dine poeng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_currentPoints > 0 && _estimatedPoints > 0) ...[
                    const SizedBox(height: 12),
                    _pointsSummaryRow('Nåværende saldo', _currentPoints),
                    _pointsSummaryRow('Estimert opptjening', _estimatedPoints, color: Colors.green),
                    const Divider(),
                    Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text('Mulig saldo etter kjøp',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                        const SizedBox(width: 8),
                        Text(_formatNum(_pointsAfter),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Smarte butikker ──
            if (_includeFlight || _includeHotel || _includeCar) ...[
              _smartStoresSection(theme),
              const SizedBox(height: 12),
            ],

            // ── AI-hjelp ──
            _aiHelpCard(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


  Widget _destinationsSection() {
    final dests = [
      {'flag':'🇳🇴','name':'Oslo → Tromsø',  'pts':'5 000', 'type':'Innenlands'},
      {'flag':'🇬🇧','name':'Oslo → London',   'pts':'15 000','type':'Europa'},
      {'flag':'🇹🇭','name':'Oslo → Bangkok',  'pts':'60 000','type':'Asia'},
      {'flag':'🇺🇸','name':'Oslo → New York', 'pts':'70 000','type':'USA'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('✈️ Populære bonusreiser',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text('Poeng fra SAS EuroBonus – én vei, Economy',
          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      const SizedBox(height: 10),
      ...dests.map((d) => GestureDetector(
        onTap: () => _launchUrl('https://www.sas.no/eurobonus/bonusreiser'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFeff6ff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF93c5fd), width: 1.5),
          ),
          child: Row(children: [
            Text(d['flag']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
              Text(d['type']!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('fra ${d['pts']} p',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      )),
      GestureDetector(
        onTap: () => _launchUrl('https://www.sas.no/eurobonus/bonusreiser'),
        child: Center(child: Text('Søk alle bonusreiser på sas.no →',
            style: TextStyle(fontSize: 12, color: const Color(0xFF2563eb), fontWeight: FontWeight.w600))),
      ),
    ]);
  }

  void _launchUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Widget _heroCard(ThemeData theme) {
    final totalPeople = _adults + _children;
    final childText = _children > 0 ? ', $_children barn' : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A4FD4), Color(0xFF0D6E44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✈️ Reise til $_destination',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 6),
          Text('$totalPeople personer ($_adults voksne$childText)',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
          if (_totalAmount > 0) ...[
            const SizedBox(height: 8),
            Text('Total reisekostnad: kr ${_formatNum(_totalAmount)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            Text('Estimert poengopptjening: ${_formatNum(_estimatedPoints)} poeng',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ] else
            const Text('Legg inn priser for å se poengopptjening',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sectionCard(ThemeData theme, {required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf0fdf4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86efac), width: 2),
      ),
      child: Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          ),
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            labelStyle: const TextStyle(color: Colors.black54),
            hintStyle: const TextStyle(color: Colors.black38),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF16a34a), fontSize: 13)),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _travelElementToggle({
    required IconData icon,
    required String label,
    required bool selected,
    required Function(bool) onToggle,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: selected ? Colors.blue.withValues(alpha: 0.05) : null,
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (v) => onToggle(v ?? false),
            title: Row(children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
            ]),
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          if (child != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _counterWidget(String label, int value, {VoidCallback? onMinus, VoidCallback? onPlus}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: onMinus,
          color: onMinus != null ? Colors.blue : Colors.grey,
        ),
        Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onPlus,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _totalSummaryCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💰 Reiseoversikt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (_includeFlight && _flightCtrl.text.isNotEmpty)
            _summaryRow('✈️ Fly', 'kr ${_formatNum(int.tryParse(_flightCtrl.text.replaceAll(" ", "")) ?? 0)}'),
          if (_includeHotel && _hotelCtrl.text.isNotEmpty)
            _summaryRow('🏨 Hotell ($_hotelNights netter)', 'kr ${_formatNum(int.tryParse(_hotelCtrl.text.replaceAll(" ", "")) ?? 0)}'),
          if (_includeCar && _carCtrl.text.isNotEmpty)
            _summaryRow('🚗 Leiebil ($_carDays dager)', 'kr ${_formatNum(int.tryParse(_carCtrl.text.replaceAll(" ", "")) ?? 0)}'),
          const Divider(),
          _summaryRow('Total', 'kr ${_formatNum(_totalAmount)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          _summaryRow('Estimert poeng', '${_formatNum(_estimatedPoints)} poeng',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade700)),
          const SizedBox(height: 8),
          Text('Basert på: $_selectedProgram • $_cardRatePer100 poeng/100 kr • ${_adults + _children} personer',
            style: const TextStyle(color: Colors.black87, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style ?? const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: style ?? const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _pointsSummaryRow(String label, int value, {Color? color, TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style ?? const TextStyle(fontWeight: FontWeight.w600)),
          Text(_formatNum(value),
            style: style ?? TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _smartStoresSection(ThemeData theme) {
    final stores = <Map<String, dynamic>>[];
    if (_includeFlight) {
      stores.addAll([
        {'icon': Icons.luggage, 'title': 'Bagasje og kofferter', 'url': 'https://onlineshopping.flysas.com/nb-NO/forslag'},
        {'icon': Icons.power, 'title': 'Elektronikk og lading', 'url': 'https://onlineshopping.flysas.com/nb-NO/forslag'},
        {'icon': Icons.health_and_safety, 'title': 'Apotek og reisehelse', 'url': 'https://www.trumf.no/fordeler?filter=Netthandel'},
      ]);
    }
    if (_includeHotel) {
      stores.addAll([
        {'icon': Icons.bed, 'title': 'Komfort og opphold', 'url': 'https://www.trumf.no/fordeler?filter=Hotell+og+reise'},
        {'icon': Icons.checkroom, 'title': 'Klær og sommerutstyr', 'url': 'https://onlineshopping.flysas.com/nb-NO/forslag'},
      ]);
    }
    if (_includeCar) {
      stores.addAll([
        {'icon': Icons.directions_car, 'title': 'Biltilbehør og komfort', 'url': 'https://www.trumf.no/fordeler?filter=Bil+og+drivstoff'},
        {'icon': Icons.child_care, 'title': 'Familie og barn på tur', 'url': 'https://www.trumf.no/fordeler?filter=Netthandel'},
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf0fdf4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86efac), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🛍️ Smarte kjøp før $_destination-reisen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
          const SizedBox(height: 4),
          Text('Tjen poeng på disse kjøpene før du reiser',
            style: const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 12),
          ...stores.map((s) => _storeRow(s, theme)),
        ],
      ),
    );
  }

  Widget _storeRow(Map<String, dynamic> store, ThemeData theme) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(store['url'] as String);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFeff6ff),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(store['icon'] as IconData, color: const Color(0xFF2563eb), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(store['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87))),
            const Icon(Icons.open_in_new, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _aiHelpCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFeff6ff), const Color(0xFFf0fdf4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93c5fd), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤖 Spør AI om reisen din',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1e40af))),
          const SizedBox(height: 6),
          Text('Få personlig råd om hvordan du maksimerer poengene til $_destination for ${_adults + _children} personer.',
            style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Åpne AI-rådgiver'),
              onPressed: () {
                // Naviger til AI-chat
                Navigator.of(context).pop();
              },
            ),
          ),
          if (!_isPremium) ...[
            const SizedBox(height: 8),
            Text('💡 Med Premium får du enda bedre reiseforslag og prioriterte tips',
              style: TextStyle(color: Colors.orange[700], fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
