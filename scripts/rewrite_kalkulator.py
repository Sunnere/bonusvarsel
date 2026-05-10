#!/usr/bin/env python3
import os

dart = r"""import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/trumf_calculator.dart';
import '../services/entitlement_service.dart';
import 'paywall_page.dart';

class TrumfKalkulatorPage extends StatefulWidget {
  const TrumfKalkulatorPage({super.key});
  @override
  State<TrumfKalkulatorPage> createState() => _TrumfKalkulatorPageState();
}

class _TrumfKalkulatorPageState extends State<TrumfKalkulatorPage> {
  double _dagligvare = 8000;
  double _mobil = 400;
  double _strom = 1200;
  bool _kredittkort = false;
  bool _trumfPay = false;
  bool _trippelTorsdag = false;
  String? _valgtButikk = 'kiwi';
  String? _valgtMobil;
  String? _valgtStrom;
  bool _isPremium = false;
  bool _isElite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoritter();
    _loadEntitlement();
  }

  Future<void> _loadEntitlement() async {
    final ent = EntitlementService.instance;
    setState(() {
      _isPremium = ent.isPremium || ent.isElite;
      _isElite = ent.isElite;
    });
  }

  Future<void> _loadFavoritter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _valgtButikk = prefs.getString('trumf_fav_dag') ?? 'kiwi';
      _valgtMobil  = prefs.getString('trumf_fav_mob');
      _valgtStrom  = prefs.getString('trumf_fav_strom');
    });
  }

  Future<void> _saveFavoritter() async {
    final prefs = await SharedPreferences.getInstance();
    if (_valgtButikk != null) await prefs.setString('trumf_fav_dag', _valgtButikk!);
    if (_valgtMobil  != null) await prefs.setString('trumf_fav_mob', _valgtMobil!);
    if (_valgtStrom  != null) await prefs.setString('trumf_fav_strom', _valgtStrom!);
  }

  double get _maanedligBonus => TrumfCalculator.beregnMaanedligBonus(
    maanedligDagligvare: _dagligvare,
    brukKredittkort: _kredittkort,
    brukTrumfPay: _trumfPay,
    maanedligMobil: _valgtMobil == 'talkmore' ? _mobil : 0,
    maanedligStrom: _valgtStrom == 'fjordkraft' ? _strom : 0,
  );

  double get _aarligBonus => _maanedligBonus * 12;
  double get _euroBonusAuto => TrumfCalculator.konverterTilEuroBonus(
      trumfKroner: _aarligBonus, automatiskOverforing: true);
  double get _euroBonusEngang => TrumfCalculator.konverterTilEuroBonus(
      trumfKroner: _aarligBonus);

  String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '\u202F',
      );

  String get _butikkNavn {
    const map = {
      'kiwi': 'KIWI', 'meny': 'MENY', 'spar': 'SPAR',
      'joker': 'Joker', 'jacobs': "Jacob's", 'naer': 'Nærbutikken',
    };
    return map[_valgtButikk] ?? 'Dagligvarer';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trumf-kalkulator'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Kalkulator'),
            Tab(text: 'Favoritter'),
          ]),
        ),
        body: TabBarView(children: [
          _buildKalkulator(),
          _buildFavoritter(),
        ]),
      ),
    );
  }

  Widget _buildKalkulator() {
    final sats = _dagligvare > 0
        ? TrumfCalculator.beregnBonus(
            belop: _dagligvare,
            brukKredittkort: _kredittkort,
            brukTrumfPay: _trumfPay,
            erTrippelTrumfTorsdag: _trippelTorsdag,
          ) / _dagligvare * 100
        : 1.0;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      _card([
        _secLabel('Forbruk per måned'),
        _slider(_butikkNavn, _dagligvare, 500, 30000, 500,
            (v) => setState(() => _dagligvare = v)),
        if (_valgtMobil == 'talkmore')
          _slider('Talkmore (mobil)', _mobil, 0, 2000, 50,
              (v) => setState(() => _mobil = v)),
        if (_valgtStrom == 'fjordkraft')
          _slider('Fjordkraft (strøm)', _strom, 0, 5000, 100,
              (v) => setState(() => _strom = v)),
      ]),
      _card([
        _secLabel('Betalingsmåte'),
        const SizedBox(height: 10),
        _togRow('💳 Kredittkort +1%', _kredittkort,
            () => setState(() => _kredittkort = !_kredittkort)),
        const SizedBox(height: 8),
        _togRow('📱 Trumf Pay +1%', _trumfPay,
            () => setState(() => _trumfPay = !_trumfPay)),
        const SizedBox(height: 8),
        _togRow('🔥 Trippel-Torsdag +2%', _trippelTorsdag,
            () => setState(() => _trippelTorsdag = !_trippelTorsdag)),
      ]),
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D6E44), Color(0xFF0A5236)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _rLabel('Månedlig bonus'),
                Text('${_fmt(_maanedligBonus)} kr',
                    style: const TextStyle(fontSize: 36,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                Text('${_fmt(_aarligBonus)} kr per år',
                    style: const TextStyle(fontSize: 12,
                        color: Color(0xFF6DCCA0))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _rLabel('Sats'),
              Text('${sats.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA8F0CC))),
            ]),
          ]),
          const Divider(color: Colors.white24, height: 28),
          _rLabel('SAS EuroBonus per år'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _euroBox('Engang',
                _euroBonusEngang, '10 p/kr', false)),
            const SizedBox(width: 10),
            Expanded(child: _euroBox('Automatisk ✓',
                _euroBonusAuto, '13,5 p/kr', true)),
          ]),
        ]),
      ),
      _secLabel('Råd for deg'),
      const SizedBox(height: 8),
      ..._tips(),
    ]);
  }

  List<Widget> _tips() {
    final dagGain = '+${_fmt(_dagligvare * 0.01 * 12)} kr/år';
    final mobGain = '+${_fmt(400 * 0.04 * 12)} kr/år';
    final strGain = '+${_fmt(1200 * 0.01 * 12)} kr/år';

    final list = <Map<String, String>>[];
    if (!_kredittkort)
      list.add({'i': '💳', 'title': 'Aktiver Trumf Kredittkort',
        'desc': 'Dobler bonus på dagligvarer. Maks 5% på Trippel-Torsdag.',
        'gain': dagGain});
    if (_valgtMobil != 'talkmore')
      list.add({'i': '📱', 'title': 'Bytt til Talkmore',
        'desc': '4% Trumf-bonus på hele mobilregningen.',
        'gain': mobGain});
    if (_valgtStrom != 'fjordkraft')
      list.add({'i': '⚡', 'title': 'Koble til Fjordkraft',
        'desc': '1% Trumf-bonus på strøm.',
        'gain': strGain});
    if (!_trippelTorsdag)
      list.add({'i': '🔥', 'title': 'Trippel-Trumf Torsdag',
        'desc': 'Legg storhandelen til torsdag for +2%.',
        'gain': ''});
    if (list.isEmpty)
      list.add({'i': '✅', 'title': 'Du er godt optimalisert!',
        'desc': 'Sett opp automatisk overføring til EuroBonus (13,5 p/kr).',
        'gain': ''});

    return list.map((t) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t['i']!, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t['title']!,
              style: const TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 13, color: Colors.white)),
          const SizedBox(height: 3),
          Text(t['desc']!,
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ])),
        if ((t['gain'] ?? '').isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(t['gain']!,
              style: const TextStyle(color: Color(0xFF4ADE80),
                  fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ]),
    )).toList();
  }

  Widget _buildFavoritter() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card([
        _secLabel('🛒 Dagligvare'),
        const SizedBox(height: 10),
        _favGrid([
          {'id': 'kiwi',   'icon': '🟡', 'name': 'KIWI',        'pct': '1%'},
          {'id': 'meny',   'icon': '🔴', 'name': 'MENY',        'pct': '1%'},
          {'id': 'spar',   'icon': '🟢', 'name': 'SPAR',        'pct': '1%'},
          {'id': 'joker',  'icon': '🃏', 'name': 'Joker',       'pct': '1%'},
          {'id': 'naer',   'icon': '🏘', 'name': 'Nærbutikken', 'pct': '1%'},
        ], _valgtButikk,
            (id) => setState(() { _valgtButikk = id; _saveFavoritter(); })),
      ]),
      _card([
        _secLabel('📱 Mobiloperatør'),
        const SizedBox(height: 10),
        _favGrid([
          {'id': 'talkmore',  'icon': '📞', 'name': 'Talkmore', 'pct': '4%'},
          {'id': 'annet_mob', 'icon': '📵', 'name': 'Annen',    'pct': '0%'},
        ], _valgtMobil,
            (id) => setState(() { _valgtMobil = id; _saveFavoritter(); })),
      ]),
      _card([
        _secLabel('⚡ Strøm'),
        const SizedBox(height: 10),
        _favGrid([
          {'id': 'fjordkraft', 'icon': '💡', 'name': 'Fjordkraft', 'pct': '1%'},
          {'id': 'annet_str',  'icon': '🔌', 'name': 'Annen',      'pct': '0%'},
        ], _valgtStrom,
            (id) => setState(() { _valgtStrom = id; _saveFavoritter(); })),
      ]),
      _card([
        Row(children: [
          Expanded(child: _secLabel('🛍️ Trumf Netthandel')),
          _badge(_isPremium ? 'Premium' : 'Lås opp',
              _isPremium ? Colors.orange : Colors.grey),
        ]),
        const SizedBox(height: 10),
        if (!_isPremium) _paywallRow('Velg opptil 5 Trumf Netthandel-favoritter'),
      ]),
      _card([
        Row(children: [
          Expanded(child: _secLabel('✈️ SAS Online Shopping')),
          _badge(_isPremium ? 'Premium' : 'Lås opp',
              _isPremium ? Colors.orange : Colors.grey),
        ]),
        const SizedBox(height: 10),
        if (!_isPremium) _paywallRow('Velg opptil 5 SAS Shopping-favoritter'),
      ]),
      _card([
        Row(children: [
          Expanded(child: _secLabel('🌍 SAS Bonusreiser & SkyTeam')),
          _badge(_isElite ? 'Elite' : 'Lås opp',
              _isElite ? Colors.blue : Colors.grey),
        ]),
        const SizedBox(height: 10),
        if (!_isElite) _paywallRow('Se bonusreiser og SkyTeam-partnere'),
      ]),
    ]);
  }

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white12),
    ),
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _secLabel(String t) => Text(t,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 0.08, color: Color(0xFF2A9D6E)));

  Widget _slider(String label, double value, double min, double max,
      double step, ValueChanged<double> cb) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        Text('${_fmt(value)} kr',
            style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
      Slider(
        value: value, min: min, max: max,
        divisions: ((max - min) / step).round(),
        activeColor: const Color(0xFF1A8A5C),
        onChanged: (v) => cb((v / step).round() * step),
      ),
    ]);
  }

  Widget _togRow(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF1A8A5C).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? const Color(0xFF1A8A5C) : Colors.white24),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: active ? const Color(0xFF4ADE80) : Colors.white70)),
        ),
      );

  Widget _favGrid(List<Map<String, String>> items, String? sel,
      ValueChanged<String> onSelect) {
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1,
      children: items.map((item) {
        final isSel = sel == item['id'];
        return GestureDetector(
          onTap: () => onSelect(item['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSel
                  ? const Color(0xFF1A8A5C).withOpacity(0.2)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isSel ? const Color(0xFF1A8A5C) : Colors.white12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(item['icon']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(item['name']!,
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: Colors.white),
                  textAlign: TextAlign.center),
              Text(item['pct']!,
                  style: TextStyle(fontSize: 10,
                      color: isSel
                          ? const Color(0xFF4ADE80)
                          : Colors.grey[500])),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _euroBox(String label, double pts, String rate, bool highlight) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF6DCCA0).withOpacity(0.15)
              : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: highlight
                  ? const Color(0xFF6DCCA0).withOpacity(0.5)
                  : Colors.white12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 10,
                  color: const Color(0xFF6DCCA0),
                  fontWeight: FontWeight.w700, letterSpacing: 0.06)),
          const SizedBox(height: 4),
          Text(_fmt(pts),
              style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w700, color: Colors.white)),
          Text('poeng/år · $rate',
              style: TextStyle(fontSize: 10, color: const Color(0xFF6DCCA0))),
        ]),
      );

  Widget _rLabel(String t) => Text(t,
      style: const TextStyle(fontSize: 11, color: Color(0xFF6DCCA0),
          fontWeight: FontWeight.w700, letterSpacing: 0.07));

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 10, color: color,
            fontWeight: FontWeight.w700)),
  );

  Widget _paywallRow(String desc) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => PaywallPage())),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Text('🔒', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(desc,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const Text('Trykk for å oppgradere',
              style: TextStyle(fontSize: 11, color: Colors.orange,
                  fontWeight: FontWeight.w600)),
        ])),
        const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
      ]),
    ),
  );
}
"""

path = os.path.expanduser('~/bonusvarsel/lib/pages/trumf_kalkulator_page.dart')
with open(path, 'w') as f:
    f.write(dart)
print('✅ trumf_kalkulator_page.dart skrevet på nytt')
