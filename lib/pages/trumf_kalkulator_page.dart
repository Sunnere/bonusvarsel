import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/entitlement_service.dart';
import '../widgets/ad_slot.dart';
import '../services/ad_service.dart';
import '../models/ad_slot.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Betalingsmåte
  String _betalingsmate = 'bankkort'; // bankkort, qr, trumfpay, kredittkort

  // EuroBonus terskel
  double _terskel = 200;

  String? _valgtButikk = 'kiwi';
  String? _valgtMobil;
  String? _valgtStrom;
  bool _isPremium = false;
  bool _isElite = false;
  bool _visMnd = true; // true = per mnd, false = per år


  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTrumfApp() async {
    final appUri = Uri.parse('trumf://');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(Uri.parse('https://www.trumf.no/'),
          mode: LaunchMode.externalApplication);
    }
  }


  void initState() {
    super.initState();
    _loadFavoritter();
    _loadEntitlement();
    EntitlementService.instance.addListener(_loadEntitlement);
  }

  @override
  void dispose() {
    EntitlementService.instance.removeListener(_loadEntitlement);
    super.dispose();
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

  // Sats basert på betalingsmåte
  double get _dagligvareSats {
    switch (_betalingsmate) {
      case 'bankkort':    return 0.01;
      case 'qr':          return 0.02;
      case 'trumfpay':    return 0.02;
      case 'kredittkort': return 0.03;
      default:            return 0.01;
    }
  }

  double get _maanedligDagligvareBonus => _dagligvare * _dagligvareSats;
  double get _maanedligMobilBonus =>
      _valgtMobil == 'talkmore' ? _mobil * 0.04 : 0;
  double get _maanedligStromBonus =>
      _valgtStrom == 'fjordkraft' ? _strom * 0.01 : 0;
  double get _maanedligBonus =>
      _maanedligDagligvareBonus + _maanedligMobilBonus + _maanedligStromBonus;
  double get _aarligBonus => _maanedligBonus * 12;

  // EuroBonus-estimat basert på terskel
  // Automatisk overføring skjer når saldo >= terskel
  // Estimert antall overføringer per måned
  double get _overforingerPerMaaned =>
      _maanedligBonus >= _terskel ? (_maanedligBonus / _terskel).floorToDouble() : (_maanedligBonus / _terskel);

  double get _euroBonusPerMaaned => _maanedligBonus * 13.5;
  double get _euroBonusPerAar => _aarligBonus * 13.5;

  // Sammenligning: engang
  double get _euroBonusEngangPerAar => _aarligBonus * 10.0;

  String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '\u202F',
      );

  String get _butikkNavn {
    const map = {
      'kiwi': 'KIWI', 'meny': 'MENY', 'spar': 'SPAR',
      'joker': 'Joker', 'naer': 'Nærbutikken',
    };
    return map[_valgtButikk] ?? 'Dagligvarer';
  }


  void _showInfo(BuildContext context, String tittel, String forklaring, {String? url}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131929),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(tittel, style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            Text(forklaring, style: TextStyle(fontSize: 14,
                color: Colors.grey[400], height: 1.6)),
            if (url != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _openUrl(url),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: AppTheme.activeBorder(),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new, size: 16, color: Colors.white54),
                      SizedBox(width: 8),
                      Text("Les mer på trumf.no", style: TextStyle(fontSize: 13,
                          color: Colors.white54, fontWeight: FontWeight.w600)),
                    ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _infoTitler = {
    "bankkort":    "💳 Vanlig bankkort – 1%",
    "qr":          "📱 QR-kode i Trumf-appen – 2%",
    "trumfpay":    "⚡ Trumf Pay – 2%",
    "kredittkort": "🏆 Trumf Kredittkort – 3%+",
  };

  static const _infoTekster = {
    "bankkort": "Registrer bankkortet ditt i Trumf-appen én gang.\n\nHver gang du betaler med det kortet i KIWI, MENY, SPAR, Joker eller Nærbutikken, registreres 1% bonus automatisk. Du trenger ikke gjøre noe i kassen.\n\n💡 Har du SAS Amex eller EuroBonus Mastercard? Registrer det og få Trumf-bonus OG EuroBonus-poeng på samme handletur – dobbel dip!",
    "qr": "Åpne Trumf-appen og trykk på QR-ikonet. Vis koden til kassapersonalet før du betaler.\n\nDu får 2% bonus – gratis og enkelt.\n\nBetaler du med SAS Amex etterpå får du 20 EuroBonus-poeng per 100 kr i tillegg.\n\n💡 Eksempel 1 000 kr med QR + SAS Amex:\n• 20 kr Trumf-bonus (2%)\n• 200 EuroBonus-poeng\n• = 270 poeng totalt ved automatisk overføring",
    "trumfpay": "Trumf Pay er betaling direkte fra Trumf-appen. Du får 2% bonus.\n\nMerk: Med Trumf Pay kan du ikke betale med kredittkort samtidig. QR-kode + SAS kredittkort gir derfor mer totalt.",
    "kredittkort": "Trumf Kredittkort gir 3% bonus normalt og 5% på Trippel-Trumf Torsdag.\n\n💡 Eksempel 1 000 kr på Trippel-Torsdag:\n• Vanlig bankkort: 10 kr (1%)\n• Trumf Kredittkort: 50 kr (5%)\n• 40 kr ekstra – bare fordi du byttet kort!",
  };

  static const _infoUrls = {
    "bankkort":    "https://www.trumf.no/slik-sparer-du-trumf-bonus/bonus-med-bankkort",
    "qr":          "https://www.trumf.no/slik-sparer-du-trumf-bonus/bonus-med-trumf-pay",
    "trumfpay":    "https://www.trumf.no/slik-sparer-du-trumf-bonus/bonus-med-trumf-pay",
    "kredittkort": "https://www.trumf.no/slik-sparer-du-trumf-bonus/bonus-med-trumf-kredittkort",
  };

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
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [

      _adBanner('spar'),
      const SizedBox(height: 8),
      // ── Forbruk ──────────────────────────────────────────
      _card([
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _secLabel('Ditt månedlige forbruk'),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF0F2340),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Hvorfor er dette viktig?',
                    style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 12),
                  const Text(
                    'Dette er det du handler for i dagligvarebutikken din per måned – '
                    'f.eks. KIWI, MENY eller SPAR.\n\n'
                    'Jo høyere beløp, desto mer Trumf-bonus tjener du. '
                    'Kalkulatoren viser deg nøyaktig hva du kan spare og hvor mange '
                    'EuroBonus-poeng du kan tjene.\n\n'
                    '💡 Gå til Favoritter-fanen for å velge hvilken butikk du '
                    'handler i – da blir utregningen enda mer presis!',
                    style: TextStyle(color: Color(0xFFCBD5E1),
                      fontSize: 14, height: 1.6)),
                ]),
              ),
            ),
            child: const Icon(Icons.info_outline_rounded,
              color: Color(0xFF2A9D6E), size: 18)),
        ]),
        _slider(_butikkNavn, _dagligvare, 500, 30000, 500,
            (v) => setState(() => _dagligvare = v)),
        if (_valgtMobil == 'talkmore')
          _slider('Talkmore (mobil)', _mobil, 0, 2000, 50,
              (v) => setState(() => _mobil = v)),
        if (_valgtStrom == 'fjordkraft')
          _slider('Fjordkraft (strøm)', _strom, 0, 5000, 100,
              (v) => setState(() => _strom = v)),
      ]),

      const SizedBox(height: 14),
      // ── Betalingsmåte ─────────────────────────────────────
      _card([
        _secLabel('Hvordan betaler du i butikken?'),
        const SizedBox(height: 4),
        const Text(
          'Jo mer du kobler til Trumf, desto mer bonus får du.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 12),
        _betalingsRow('bankkort', '💳', '1% – Vanlig bankkort',
            'Registrer bankkortet ditt i Trumf-appen én gang.\nDu får bonus automatisk – uten å gjøre noe i kassen.'),
        const SizedBox(height: 8),
        _betalingsRow('qr', '📱', '2% – Scan QR-koden i Trumf-appen',
            'Åpne Trumf-appen og scan QR-koden i kassen.\nDu får dobbel bonus – enkelt og gratis.'),
        const SizedBox(height: 8),
        _betalingsRow('trumfpay', '⚡', '2% – Trumf Pay',
            'Betal direkte fra Trumf-appen.\nSamme bonus som QR-skanning.'),
        const SizedBox(height: 8),
        _betalingsRow('kredittkort', '🏆', '3%+ – Trumf Kredittkort',
            'Søk om Trumf Kredittkort (Visa eller Mastercard).\nGir 3% normalt og opptil 5% på Trippel-Torsdag.'),
      ]),

      // ── Resultat ──────────────────────────────────────────
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A4FD4), Color(0xFF0D6E44)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Mnd/År-toggle
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _rLabel('Trumf-bonus du sparer'),
            GestureDetector(
              onTap: () => setState(() => _visMnd = !_visMnd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _visMnd ? 'per måned  →  år' : 'per år  →  mnd',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            _visMnd
                ? '${_fmt(_maanedligBonus)} kr / mnd'
                : '${_fmt(_aarligBonus)} kr / år',
            style: const TextStyle(fontSize: 38,
                fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Text(
            _visMnd
                ? '≈ ${_fmt(_aarligBonus)} kr per år'
                : '≈ ${_fmt(_maanedligBonus)} kr per måned',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6DCCA0)),
          ),

          const Divider(color: Colors.white24, height: 28),

          // EuroBonus-seksjon
          _rLabel('Verdi i SAS EuroBonus'),
          const SizedBox(height: 4),

          // Terskel-velger
          Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Automatisk overføring ved:',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
            ...[50.0, 100.0, 200.0].map((t) => GestureDetector(
              onTap: () => setState(() => _terskel = t),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _terskel == t
                      ? const Color(0xFF6DCCA0).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _terskel == t
                        ? const Color(0xFF6DCCA0)
                        : Colors.transparent,
                  ),
                ),
                child: Text('${t.toInt()} kr',
                    style: TextStyle(
                      fontSize: 11,
                      color: _terskel == t
                          ? const Color(0xFF6DCCA0)
                          : Colors.white60,
                      fontWeight: _terskel == t
                          ? FontWeight.w700
                          : FontWeight.normal,
                    )),
              ),
            )),
          ]),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: _euroBox(
              'Engangsoverføring',
              _visMnd ? _maanedligBonus * 10 : _euroBonusEngangPerAar,
              '10 poeng per krone',
              false,
            )),
            const SizedBox(width: 10),
            Expanded(child: _euroBox(
              'Automatisk ✓',
              _visMnd ? _euroBonusPerMaaned : _euroBonusPerAar,
              '13,5 poeng per krone',
              true,
            )),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Med automatisk overføring ved ${_terskel.toInt()} kr får du '
              '${_fmt(_terskel * 13.5)} poeng per overføring – '
              '${_fmt(13.5 / 10 * 100 - 100).replaceAll('-', '')} % mer enn ved engangsoverføring.',
              style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.5),
            ),
          ),
        ]),
      ),

      // ── Råd ──────────────────────────────────────────────
      _secLabel('Råd for deg'),
      const SizedBox(height: 8),
      ..._tips(),
    ]);
  }

  List<Widget> _tips() {
    final list = <Map<String, dynamic>>[];

    // Bankkort-tips
    if (_betalingsmate == 'bankkort') {
      list.add({
        'i': '📱', 'color': Colors.blue,
        'title': 'Scan QR-koden – dobbel bonus på sekunder',
        'desc': 'Åpne Trumf-appen og trykk på QR-ikonet i kassen. '
            'Du går fra 1% til 2% bonus – det tar 5 sekunder og er helt gratis.',
        'gain': '+${_fmt(_dagligvare * 0.01 * 12)} kr/år ekstra',
      });
    }

    if (_betalingsmate != 'kredittkort') {
      list.add({
        'i': '🏆', 'color': Colors.amber,
        'title': 'Søk om Trumf Kredittkort',
        'desc': 'Med Trumf Kredittkort (Visa eller Mastercard fra Trumf) '
            'får du 3% bonus på alle dagligvarer normalt, '
            'og hele 5% på Trippel-Trumf Torsdag. '
            'Kortet søker du om på trumf.no.',
        'gain': '+${_fmt(_dagligvare * 0.02 * 12)} kr/år ekstra',
      });
    }

    // Talkmore
    if (_valgtMobil != 'talkmore') {
      list.add({
        'i': '📞', 'color': Colors.green,
        'title': 'Bytt mobilabonnement til Talkmore',
        'desc': 'Talkmore er Trumfs eget mobilselskap. '
            'Du får 4% av hele mobilregningen din som Trumf-bonus hver måned. '
            'Dekningsområde: hele Telenor-nettet.',
        'gain': '+${_fmt(400 * 0.04 * 12)} kr/år',
      });
    }

    // Fjordkraft
    if (_valgtStrom != 'fjordkraft') {
      list.add({
        'i': '⚡', 'color': Colors.orange,
        'title': 'Bytt strømleverandør til Fjordkraft',
        'desc': 'Med Fjordkraft som strømleverandør får du 1% av hele '
            'strømregningen som Trumf-bonus automatisk hver måned.',
        'gain': '+${_fmt(1200 * 0.01 * 12)} kr/år',
      });
    }

    // Trippel-Torsdag
    list.add({
      'i': '🔥', 'color': Colors.deepOrange,
      'title': 'Gjør storhandelen på Trippel-Trumf Torsdag',
      'desc': 'Noen torsdager er det "Trippel-Trumf" – da får du 3× grunnbonusen din i stedet for 1×. '
          'Har du Trumf Kredittkort, får du hele 5%.\n\n'
          '🥦 Frukt og grønt hos KIWI: opptil 15% med KIWI PLUSS\n'
          '🌮 Taco-produkter hos MENY: opptil 40% med MENY MER\n'
          '🛒 Joker-kunder: 6% på alt hver mandag med Joker GLAD\n\n'
          'Sjekk Trumf-appen for å se neste Trippel-Torsdag-dato.',
      'gain': '',
    });

    if (list.isEmpty) {
      list.add({
        'i': '✅', 'color': Colors.green,
        'title': 'Du er godt optimalisert!',
        'desc': 'Husk å sette opp automatisk overføring til EuroBonus i Trumf-appen. '
            'Du får 35% mer poeng enn ved manuell overføring.',
        'gain': '',
      });
    }

    return list.map((t) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: AppTheme.activeBorder(),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(t['i'] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14, color: Colors.white)),
          ),
          if ((t['gain'] as String).isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t['gain'] as String,
                  style: const TextStyle(color: Color(0xFF4ADE80),
                      fontWeight: FontWeight.w700, fontSize: 11)),
            ),
        ]),
        const SizedBox(height: 8),
        Text(t['desc'] as String,
            style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.5)),
      ]),
    )).toList();
  }

  // ── FAVORITTER ────────────────────────────────────────────
  Widget _buildFavoritter() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _adBanner('spar_favoritter'),
      const SizedBox(height: 8),
      const Text(
        'Velg dine faste butikker og partnere.\nKalkulatoren oppdateres automatisk.',
        style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.5),
      ),
      const SizedBox(height: 16),
      _card([
        _secLabel('🛒 Hvilken dagligvarebutikk bruker du mest?'),
        const SizedBox(height: 10),
        _favGridLogo([
          {'id': 'kiwi',  'color': 0xFFFFD600, 'textColor': 0xFF1A1A1A, 'name': 'KIWI',        'pct': '1%'},
          {'id': 'meny',  'color': 0xFFE4001B, 'textColor': 0xFFFFFFFF, 'name': 'MENY',        'pct': '1%'},
          {'id': 'spar',  'color': 0xFF007A3D, 'textColor': 0xFFFFFFFF, 'name': 'SPAR',        'pct': '1%'},
          {'id': 'joker', 'color': 0xFF1A1A2E, 'textColor': 0xFFFFFFFF, 'name': 'Joker',       'pct': '1%'},
          {'id': 'naer',  'color': 0xFF2563EB, 'textColor': 0xFFFFFFFF, 'name': 'Nær',         'pct': '1%'},
        ], _valgtButikk,
            (id) => setState(() { _valgtButikk = id; _saveFavoritter(); })),
      ]),
      _card([
        _secLabel('📱 Har du Talkmore mobilabonnement?'),
        const SizedBox(height: 4),
        const Text('Talkmore gir 4% Trumf-bonus på hele mobilregningen.',
            style: TextStyle(fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 10),
        _favGrid([
          {'id': 'talkmore',  'icon': '📞', 'name': 'Ja, Talkmore', 'pct': '4%'},
          {'id': 'annet_mob', 'icon': '📵', 'name': 'Annet',        'pct': '0%'},
        ], _valgtMobil,
            (id) => setState(() { _valgtMobil = id; _saveFavoritter(); })),
      ]),
      _card([
        _secLabel('⚡ Har du Fjordkraft som strømleverandør?'),
        const SizedBox(height: 4),
        const Text('Fjordkraft gir 1% Trumf-bonus på strømregningen.',
            style: TextStyle(fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 10),
        _favGrid([
          {'id': 'fjordkraft', 'icon': '💡', 'name': 'Ja, Fjordkraft', 'pct': '1%'},
          {'id': 'annet_str',  'icon': '🔌', 'name': 'Annet',          'pct': '0%'},
        ], _valgtStrom,
            (id) => setState(() { _valgtStrom = id; _saveFavoritter(); })),
      ]),
      _card([
        Row(children: [
          Expanded(child: _secLabel('🛍️ Trumf Netthandel – opptil 10%')),
          _badge(_isElite ? 'Elite' : _isPremium ? 'Premium' : 'Lås opp',
              _isElite ? Colors.blue : _isPremium ? Colors.orange : Colors.grey),
        ]),
        const SizedBox(height: 6),
        const Text(
          'Velg nettbutikker du bruker ofte.\nDu får varsel når de har ekstra bonus.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        if (!_isPremium) _paywallRow('Velg opptil 5 Trumf Netthandel-favoritter'),
      ]),
      _card([
        Row(children: [
          Expanded(child: _secLabel('✈️ SAS Online Shopping')),
          _badge(_isElite ? 'Elite' : _isPremium ? 'Premium' : 'Lås opp',
              _isElite ? Colors.blue : _isPremium ? Colors.orange : Colors.grey),
        ]),
        const SizedBox(height: 6),
        const Text(
          'Handle via SAS-portalen og tjen EuroBonus-poeng direkte.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        if (!_isPremium) _paywallRow('Velg opptil 5 SAS Shopping-favoritter'),
      ]),
      _card([
        Row(children: [
          Expanded(child: _secLabel('🌍 SAS Bonusreiser & SkyTeam')),
          _badge(_isElite ? 'Elite' : 'Lås opp',
              _isElite ? Colors.blue : Colors.grey),
        ]),
        const SizedBox(height: 6),
        const Text(
          'Følg med på tilgjengelige bonusreiser med SAS, Air France, KLM, Delta og flere.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        if (!_isElite)
          _paywallRow('Tilgjengelig i Elite-abonnement')
        else
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2340),
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.activeBorder(),
            ),
            child: Row(children: [
              const Text('🚀', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'SAS Bonusreiser og SkyTeam-varsler kommer snart til Elite.',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4))),
            ]),
          ),
      ]),
    ]);
  }

  // ── WIDGETS ───────────────────────────────────────────────
  Widget _adBanner(String placement) {
    return FutureBuilder<List<AdSlot>>(
      future: AdService.instance.pickAds(placement: placement, count: 1),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        return AdSlotCard(slot: snap.data!.first, placement: placement);
      },
    );
  }

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(18),
      border: AppTheme.activeBorder(),
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

  Widget _betalingsRow(String id, String icon, String label, String desc) {
    final isActive = _betalingsmate == id;
    return GestureDetector(
      onTap: () => setState(() => _betalingsmate = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1A8A5C).withOpacity(0.15)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? const Color(0xFF1A8A5C) : Colors.white12),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF4ADE80) : Colors.white)),
            const SizedBox(height: 3),
            Text(desc,
                style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4)),
          ])),
          if (isActive)
            const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 20),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showInfo(
                context,
                _infoTitler[id] ?? label,
                _infoTekster[id] ?? desc,
                url: _infoUrls[id],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, size: 16, color: Colors.white38),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _favGrid(List<Map<String, String>> items, String? sel,
      ValueChanged<String> onSelect) {
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.0,
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
                  style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600, color: Colors.white),
                  textAlign: TextAlign.center),
              Text(item['pct']!,
                  style: TextStyle(fontSize: 10,
                      color: isSel ? const Color(0xFF4ADE80) : Colors.grey[500])),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _favGridLogo(List<Map<String, dynamic>> items, String? sel,
      ValueChanged<String> onSelect) {
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1,
      children: items.map((item) {
        final isSel = sel == item['id'];
        final bgColor = Color(item['color'] as int);
        final txtColor = Color(item['textColor'] as int);
        return GestureDetector(
          onTap: () => onSelect(item['id'] as String),
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
              Container(
                width: 48, height: 28,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(item['name'] as String,
                  style: TextStyle(color: txtColor,
                    fontWeight: FontWeight.w900, fontSize: 12))),
              ),
              const SizedBox(height: 4),
              Text(item['pct'] as String,
                style: TextStyle(fontSize: 10,
                  color: isSel ? const Color(0xFF4ADE80) : Colors.grey[500])),
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
              style: const TextStyle(fontSize: 10, color: Color(0xFF6DCCA0),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_fmt(pts),
              style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w700, color: Colors.white)),
          Text(rate,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6DCCA0))),
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
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
