import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/ad_slot.dart';
import '../services/ad_service.dart';
import '../models/ad_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/entitlement_service.dart';

class BonusvarselAlertsPage extends StatefulWidget {
  const BonusvarselAlertsPage({super.key});
  @override
  State<BonusvarselAlertsPage> createState() => _BonusvarselAlertsPageState();
}

class _BonusvarselAlertsPageState extends State<BonusvarselAlertsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _activeAlerts = [];
  final _emailCtrl = TextEditingController();
  final _telegramCtrl = TextEditingController();
  bool _emailSaved = false;
  bool _telegramSaved = false;
  String _emailValue = "";
  String _telegramValue = "";
  List<Map<String, dynamic>> _trumfShops = [];
  List<String> _trumfFavIds = [];
  bool _trumfLoading = true;
  int _trumfCatId = -1;
  String _trumfSearch = "";
  bool _showTrumf = false;
  List<String> _sasFavIds = [];
  int _sasCatIdx = 0;
  String _sasSearch = "";
  bool _showSas = false;

  static const _kEmail     = "alert_email";
  static const _kTelegram  = "alert_telegram";
  static const _kTrumfFavs = "alert_trumf_favs";
  static const _kSasFavs   = "alert_sas_favs";

  static const _tGreen  = Color(0xFF16a34a);
  static const _tGreenL = Color(0xFF4ADE80);
  static const _tBg     = Color(0xFF0B1728);
  static const _tBorder = Color(0xFF34D399);
  static const _sBlue   = Color(0xFF2563eb);
  static const _sBlueL  = Color(0xFF93c5fd);
  static const _sBg     = Color(0xFF0B1728);
  static const _sBorder = Color(0xFF60A5FA);

  static const _trumfCats = [
    {"id": -1, "icon": "⭐", "name": "Kampanjer"},
    {"id": 1,  "icon": "🌍", "name": "Reise"},
    {"id": 6,  "icon": "👗", "name": "Mote"},
    {"id": 8,  "icon": "🏅", "name": "Sport"},
    {"id": 4,  "icon": "📱", "name": "Elektronikk"},
    {"id": 9,  "icon": "🏠", "name": "Bolig"},
    {"id": 2,  "icon": "💄", "name": "Velvære"},
    {"id": 3,  "icon": "🎭", "name": "Underholdning"},
    {"id": 14, "icon": "👶", "name": "Barn"},
    {"id": 13, "icon": "🐾", "name": "Dyr"},
  ];

  static const _sasCats = [
    {"icon": "⭐", "name": "Alle",       "url": "https://onlineshopping.flysas.com/nb-NO"},
    {"icon": "🌍", "name": "Reise",      "url": "https://onlineshopping.flysas.com/nb-NO/kategori/reise"},
    {"icon": "👗", "name": "Mote",       "url": "https://onlineshopping.flysas.com/nb-NO/kategori/mote"},
    {"icon": "🏅", "name": "Sport",      "url": "https://onlineshopping.flysas.com/nb-NO/kategori/sport"},
    {"icon": "📱", "name": "Elektronikk","url": "https://onlineshopping.flysas.com/nb-NO/kategori/elektronikk"},
    {"icon": "🏠", "name": "Bolig",      "url": "https://onlineshopping.flysas.com/nb-NO/kategori/bolig"},
    {"icon": "💄", "name": "Velvære",    "url": "https://onlineshopping.flysas.com/nb-NO/kategori/velvaere"},
    {"icon": "🎭", "name": "Underholdning","url": "https://onlineshopping.flysas.com/nb-NO/kategori/underholdning"},
  ];

  static const List<Map<String, dynamic>> _sasShops = [
    {"id":"sas_booking", "name":"Booking.com",   "cat":0,"pts":15,"popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/booking-com"},
    {"id":"sas_hotels",  "name":"Hotels.com",    "cat":0,"pts":15,"popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/hotels-com"},
    {"id":"sas_expedia", "name":"Expedia",       "cat":1,"pts":20,"popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/expedia"},
    {"id":"sas_scandic", "name":"Scandic Hotels","cat":1,"pts":20,"popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/scandic"},
    {"id":"sas_hertz",   "name":"Hertz",         "cat":1,"pts":15,"popular":false,"url":"https://onlineshopping.flysas.com/nb-NO/butikk/hertz"},
    {"id":"sas_rad",     "name":"Radisson",      "cat":1,"pts":18,"popular":false,"url":"https://onlineshopping.flysas.com/nb-NO/butikk/radisson"},
    {"id":"sas_hm",      "name":"H&M",           "cat":2,"pts":10,"popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/hm"},
    {"id":"sas_zal",     "name":"Zalando",       "cat":2,"pts":8, "popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/zalando"},
    {"id":"sas_asos",    "name":"ASOS",          "cat":2,"pts":10,"popular":false,"url":"https://onlineshopping.flysas.com/nb-NO/butikk/asos"},
    {"id":"sas_nelly",   "name":"Nelly",         "cat":2,"pts":12,"popular":false,"url":"https://onlineshopping.flysas.com/nb-NO/butikk/nelly"},
    {"id":"sas_nike",    "name":"Nike",          "cat":3,"pts":8, "popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/nike"},
    {"id":"sas_adidas",  "name":"Adidas",        "cat":3,"pts":8, "popular":false,"url":"https://onlineshopping.flysas.com/nb-NO/butikk/adidas"},
    {"id":"sas_apple",   "name":"Apple",         "cat":4,"pts":5, "popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/apple"},
    {"id":"sas_elkjop",  "name":"Elkjøp",        "cat":4,"pts":6, "popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/elkjop"},
    {"id":"sas_ikea",    "name":"IKEA",          "cat":5,"pts":6, "popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/ikea"},
    {"id":"sas_blivak",  "name":"Blivakker",     "cat":6,"pts":12,"popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/blivakker"},
    {"id":"sas_disney",  "name":"Disney+",        "cat":7,"pts":8, "popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/disney-plus"},
    {"id":"sas_spotify", "name":"Spotify",       "cat":7,"pts":5, "popular":true, "url":"https://onlineshopping.flysas.com/nb-NO/butikk/spotify"},
  ];

  void _onEntitlementChanged() { if (mounted) setState(() {}); }

  bool get _isPremium => EntitlementService.instance.isPremium || EntitlementService.instance.isElite;
  int get _maxFavs => EntitlementService.instance.isElite ? 10 : (_isPremium ? 5 : 0);

  @override
  void initState() {
    super.initState();
    EntitlementService.instance.addListener(_onEntitlementChanged);
    _loadPrefs();
    _loadAlerts();
    _loadTrumfShops();
  }


  Widget _adBanner(String placement) {
    return FutureBuilder<List<AdSlot>>(
      future: AdService.instance.pickAds(placement: placement, count: 1),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AdSlotCard(slot: snap.data!.first, placement: placement),
        );
      },
    );
  }

  @override
  void dispose() {
    EntitlementService.instance.removeListener(_onEntitlementChanged);
    _emailCtrl.dispose();
    _telegramCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailValue    = prefs.getString(_kEmail) ?? "";
      _telegramValue = prefs.getString(_kTelegram) ?? "";
      _emailSaved    = _emailValue.isNotEmpty;
      _telegramSaved = _telegramValue.isNotEmpty;
      _emailCtrl.text    = _emailValue;
      _telegramCtrl.text = _telegramValue;
      _trumfFavIds = prefs.getStringList(_kTrumfFavs) ?? [];
      _sasFavIds   = prefs.getStringList(_kSasFavs)   ?? [];
    });
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    try {
      final health = await ApiService.getHealth();
      final pipeline = health["pipeline"] is Map
          ? Map<String, dynamic>.from(health["pipeline"] as Map) : <String, dynamic>{};
      final notifications = pipeline["notifications"] is Map
          ? Map<String, dynamic>.from(pipeline["notifications"] as Map) : <String, dynamic>{};
      final itemsRaw = notifications["items"] is List
          ? (notifications["items"] as List) : const [];
      final items = itemsRaw.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() { _activeAlerts = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _activeAlerts = []; _loading = false; });
    }
  }

  Future<void> _loadTrumfShops() async {
    try {
      final res = await http.get(Uri.parse(
        "https://raw.githubusercontent.com/Sunnere/bonusvarsel/local-stable-baseline/data/shops.normalized.json"
      )).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(res.body) as List;
        final shops = decoded.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)).toList();
        shops.sort((a, b) {
          final aC = (a["has_campaign"] ?? 0) == 1 ? 1 : 0;
          final bC = (b["has_campaign"] ?? 0) == 1 ? 1 : 0;
          if (aC != bC) return bC.compareTo(aC);
          final aP = (a["points_campaign"] ?? 0) > 0 ? a["points_campaign"] : a["points"] ?? 0;
          final bP = (b["points_campaign"] ?? 0) > 0 ? b["points_campaign"] : b["points"] ?? 0;
          return (bP as num).compareTo(aP as num);
        });
        if (mounted) setState(() { _trumfShops = shops; _trumfLoading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() {
      _trumfShops = [
        {"uuid":"tn_outnorth","name":"Outnorth","slug":"outnorth","categoryId":8,"points":25,"points_campaign":50,"has_campaign":1},
        {"uuid":"tn_gina","name":"Gina Tricot","slug":"gina-tricot","categoryId":6,"points":30,"points_campaign":60,"has_campaign":1},
        {"uuid":"tn_smart","name":"SmartBuyGlasses","slug":"smartbuyglasses","categoryId":4,"points":40,"points_campaign":80,"has_campaign":1},
        {"uuid":"tn_hotels","name":"Hotels.com","slug":"hotels-com","categoryId":1,"points":35,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_expedia","name":"Expedia","slug":"expedia","categoryId":1,"points":35,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_scandic","name":"Scandic","slug":"scandic","categoryId":1,"points":40,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_hm","name":"H&M","slug":"hm","categoryId":6,"points":20,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_zalando","name":"Zalando","slug":"zalando","categoryId":6,"points":15,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_komplett","name":"Komplett","slug":"komplett","categoryId":4,"points":10,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_blivakker","name":"Blivakker","slug":"blivakker","categoryId":2,"points":30,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_xxl","name":"XXL","slug":"xxl","categoryId":8,"points":20,"points_campaign":0,"has_campaign":0},
        {"uuid":"tn_ikea","name":"IKEA","slug":"ikea","categoryId":9,"points":10,"points_campaign":0,"has_campaign":0},
      ];
      _trumfLoading = false;
    });
  }

  Future<void> _saveEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
    setState(() { _emailValue = email; _emailSaved = true; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("E-post lagret!")));
  }

  Future<void> _saveTelegram() async {
    final tg = _telegramCtrl.text.trim();
    if (tg.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTelegram, tg);
    setState(() { _telegramValue = tg; _telegramSaved = true; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Telegram lagret!")));
  }


  Future<void> _syncFavoritesToServer({required List<String> trumf, required List<String> sas}) async {
    debugPrint('SYNC: email=$_emailValue trumf=$trumf');
    try {
      if (!ApiService.hasUsableBaseUrl) return;
      final email = _emailValue.isNotEmpty 
          ? _emailValue 
          : FirebaseAuth.instance.currentUser?.email;
      await ApiService.updateDeviceFavorites(
        trumfFavs: trumf,
        sasFavs: sas,
        email: email,
      );
    } catch (e) {
      debugPrint('Sync favorites feilet: \$e');
    }
  }

  Future<void> _toggleTrumf(String id) async {
    if (!_isPremium) { Navigator.of(context).pushNamed("/premium"); return; }
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_trumfFavIds);
    if (updated.contains(id)) { updated.remove(id); }
    else if (updated.length < _maxFavs) { updated.add(id); }
    else { _snackMax(); return; }
    await prefs.setStringList(_kTrumfFavs, updated);
    setState(() => _trumfFavIds = updated);
    _syncFavoritesToServer(trumf: updated, sas: _sasFavIds);
  }

  Future<void> _toggleSas(String id) async {
    if (!_isPremium) { Navigator.of(context).pushNamed("/premium"); return; }
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_sasFavIds);
    if (updated.contains(id)) { updated.remove(id); }
    else if (updated.length < _maxFavs) { updated.add(id); }
    else { _snackMax(); return; }
    await prefs.setStringList(_kSasFavs, updated);
    setState(() => _sasFavIds = updated);
    _syncFavoritesToServer(trumf: _trumfFavIds, sas: updated);
  }

  void _snackMax() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Maks $_maxFavs favoritter valgt – Elite gir deg 10"),
        action: SnackBarAction(
          label: 'Oppgrader til Elite',
          onPressed: () => Navigator.of(context).pushNamed('/premium'),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  List<Map<String, dynamic>> get _trumfFiltered {
    List<Map<String, dynamic>> s = _trumfCatId == -1
        ? List<Map<String, dynamic>>.from(_trumfShops)
        : _trumfShops.where((s) => s["categoryId"] == _trumfCatId).toList();
    if (_trumfSearch.isNotEmpty) {
      s = s.where((x) => (x["name"] as String? ?? "").toLowerCase()
          .contains(_trumfSearch.toLowerCase())).toList();
    }
    return s;
  }

  List<Map<String, dynamic>> get _sasFiltered {
    List<Map<String, dynamic>> s = _sasCatIdx == 0
        ? List<Map<String, dynamic>>.from(_sasShops)
        : _sasShops.where((x) => x["cat"] == _sasCatIdx).toList();
    if (_sasSearch.isNotEmpty) {
      s = s.where((x) => (x["name"] as String? ?? "").toLowerCase()
          .contains(_sasSearch.toLowerCase())).toList();
    }
    return s;
  }

  String get _trumfCatUrl {
    const m = {1:"reise",6:"mote",8:"sport",4:"elektronikk",9:"bolig",2:"velvaere",3:"underholdning",14:"barn",13:"dyr"};
    return _trumfCatId == -1
        ? "https://trumfnetthandel.no/kategori/ukens-tilbud"
        : "https://trumfnetthandel.no/kategori/${m[_trumfCatId] ?? ""}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Varsler"),
        actions: [IconButton(onPressed: _loadAlerts, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _adBanner('varsler'),
          const SizedBox(height: 8),
          _hero(),
          const SizedBox(height: 20),
          if (_loading) const Center(child: CircularProgressIndicator())
          else if (_activeAlerts.isNotEmpty) ...[
            _h2("🏆 Aktive bonusvarsler"),
            const SizedBox(height: 8),
            ..._activeAlerts.asMap().entries.map((e) => _alertCard(e.value, e.key)),
            const SizedBox(height: 20),
          ],
          _badge("🛒 TRUMF NETTHANDEL", _tGreen),
          const SizedBox(height: 8),
          _trumfBox(),
          const SizedBox(height: 20),
          _badge("✈️ SAS ONLINE SHOPPING", _sBlue),
          const SizedBox(height: 8),
          _sasBox(),
          const SizedBox(height: 24),
          _h2("📧 E-postvarsler"),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _saveEmail(),
            decoration: InputDecoration(
              labelText: "Din e-postadresse",
              hintText: "navn@example.com",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_emailSaved ? Icons.check_circle : Icons.save,
                    color: _emailSaved ? Colors.green : null),
                onPressed: _saveEmail,
              ),
            ),
          ),
          if (_emailSaved) ...[
            const SizedBox(height: 6),
            Text("✅ Varsler sendes til $_emailValue",
                style: TextStyle(color: const Color(0xFF34D399), fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          _h2("✈️ Telegram-varsler"),
          const SizedBox(height: 4),
          const Text("Legg til @BonusvarselBot og skriv inn brukernavn:",
              style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _telegramCtrl,
              onSubmitted: (_) => _saveTelegram(),
              decoration: InputDecoration(
                labelText: "Telegram-brukernavn",
                hintText: "@dittbrukernavn",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_telegramSaved ? Icons.check_circle : Icons.save,
                      color: _telegramSaved ? Colors.green : null),
                  onPressed: _saveTelegram,
                ),
              ),
            )),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse("https://t.me/BonusvarselBot")),
              child: const Text("Åpne Bot"),
            ),
          ]),
          if (_telegramSaved) ...[
            const SizedBox(height: 6),
            Text("✅ Varsler sendes til $_telegramValue",
                style: TextStyle(color: const Color(0xFF34D399), fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0A4FD4), Color(0xFF0D6E44)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("🔔 Bonusvarsler",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      const SizedBox(height: 8),
      const Text("Velg butikkene du handler i. Vi varsler deg når de har ekstra bonus.",
          style: TextStyle(color: Colors.white70, height: 1.4)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        _hchip("Aktive", _activeAlerts.length.toString()),
        _hchip("Trumf", "${_trumfFavIds.length}/$_maxFavs"),
        _hchip("SAS", "${_sasFavIds.length}/$_maxFavs"),
      ]),
    ]),
  );

  Widget _trumfBox() => Container(
    decoration: BoxDecoration(
      color: _tBg, borderRadius: BorderRadius.circular(20),
      border: AppTheme.activeBorder()),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width:36,height:36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors:[Color(0xFF16a34a),Color(0xFF166534)]),
            borderRadius: BorderRadius.circular(10)),
          child: const Center(child: Text("Trumf",
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
              color: Color(0xFF34D399))))),
        const SizedBox(width:10),
        const Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text("Trumf Netthandel",style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:const Color(0xFF34D399))),
          Text("250+ butikker · Bonus overføres til EuroBonus",style:TextStyle(fontSize:11,color:const Color(0xFF6EE7B7))),
        ])),
      ]),
      const SizedBox(height:12),
      if (_trumfFavIds.isNotEmpty) ...[
        Wrap(spacing:6,runSpacing:6,children:_trumfFavIds.map((id){
          final shop=_trumfShops.firstWhere((s)=>s["uuid"]==id,orElse:()=>{"name":id});
          final name=(shop["name"] as String?)??id;
          return GestureDetector(onTap:()=>_toggleTrumf(id),child:Container(
            padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
            decoration:BoxDecoration(color:_tGreen.withOpacity(0.15),borderRadius:BorderRadius.circular(20),border:Border.all(color:_tGreen)),
            child:Row(mainAxisSize:MainAxisSize.min,children:[
              Text(name,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:const Color(0xFF34D399))),
              const SizedBox(width:4),const Icon(Icons.close,size:12,color:const Color(0xFF6EE7B7)),
            ]),
          ));
        }).toList()),
        const SizedBox(height:10),
      ],
      _toggleBtn(_isPremium,_showTrumf,"${_trumfFavIds.length}/$_maxFavs",_tGreen,
          (){if(!_isPremium){Navigator.of(context).pushNamed("/premium");return;}setState(()=>_showTrumf=!_showTrumf);}),
      if (_showTrumf&&_isPremium)...[
        const SizedBox(height:12),
        _catRow(_trumfCats.map((c)=>{"id":c["id"],"icon":c["icon"],"name":c["name"],"count":
          (c["id"] as int)==-1?_trumfShops.where((s)=>(s["has_campaign"]??0)==1).length
          :_trumfShops.where((s)=>s["categoryId"]==c["id"]).length}).toList(),
          _trumfCatId,(id)=>setState((){_trumfCatId=id as int;_trumfSearch="";}),_tGreen,true),
        const SizedBox(height:8),
        _searchRow(_trumfSearch,(v)=>setState(()=>_trumfSearch=v),_tGreen,_trumfCatUrl),
        const SizedBox(height:8),
        if(_trumfLoading) const Center(child:CircularProgressIndicator(strokeWidth:2))
        else ..._trumfFiltered.take(20).map((shop){
          final id=(shop["uuid"]??"") as String;
          final name=(shop["name"]??"") as String;
          final pts=((shop["points_campaign"]??0)>0?shop["points_campaign"]:shop["points"]??0);
          final np=shop["points"]??0;
          final hc=(shop["has_campaign"]??0)==1;
          final slug=(shop["slug"] as String?)??"";
          return _shopRow(name:name,pts:pts.toString(),normalPts:np.toString(),
            hasCamp:hc,isSel:_trumfFavIds.contains(id),accent:_tGreen,accentL:_tGreenL,
            onTap:()=>_toggleTrumf(id),
            onLink:slug.isNotEmpty?()=>launchUrl(Uri.parse("https://trumfnetthandel.no/butikk/$slug"),mode:LaunchMode.externalApplication):null);
        }),
        const SizedBox(height:8),
        _seeAll("↗ Se alle butikker på Trumf Netthandel","https://trumfnetthandel.no/",_tGreen),
      ],
    ]),
  );

  Widget _sasBox() => Container(
    decoration: BoxDecoration(
      color: _sBg, borderRadius: BorderRadius.circular(20),
      border: AppTheme.activeBorder()),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width:36,height:36,
          decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[Color(0xFF2563eb),Color(0xFF1d4ed8)]),
            borderRadius:BorderRadius.circular(10)),
          child:const Center(child:Text("✈️",style:TextStyle(fontSize:18)))),
        const SizedBox(width:10),
        const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text("SAS Online Shopping",style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:const Color(0xFF60A5FA))),
          Text("400+ butikker · Tjen EuroBonus-poeng direkte",style:TextStyle(fontSize:11,color:const Color(0xFF93C5FD))),
        ])),
      ]),
      const SizedBox(height:12),
      if (_sasFavIds.isNotEmpty) ...[
        Wrap(spacing:6,runSpacing:6,children:_sasFavIds.map((id){
          final shop=_sasShops.firstWhere((s)=>s["id"]==id,orElse:()=>{"name":id});
          final name=(shop["name"] as String?)??id;
          return GestureDetector(onTap:()=>_toggleSas(id),child:Container(
            padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
            decoration:BoxDecoration(color:_sBlue.withOpacity(0.1),borderRadius:BorderRadius.circular(20),border:Border.all(color:_sBlue)),
            child:Row(mainAxisSize:MainAxisSize.min,children:[
              Text(name,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:const Color(0xFF60A5FA))),
              const SizedBox(width:4),const Icon(Icons.close,size:12,color:const Color(0xFF93C5FD)),
            ]),
          ));
        }).toList()),
        const SizedBox(height:10),
      ],
      _toggleBtn(_isPremium,_showSas,"${_sasFavIds.length}/$_maxFavs",_sBlue,
          (){if(!_isPremium){Navigator.of(context).pushNamed("/premium");return;}setState(()=>_showSas=!_showSas);}),
      if (_showSas&&_isPremium)...[
        const SizedBox(height:12),
        _catRow(_sasCats.asMap().entries.map((e)=>{"id":e.key,"icon":e.value["icon"],"name":e.value["name"],"count":0}).toList(),
          _sasCatIdx,(i)=>setState((){_sasCatIdx=i as int;_sasSearch="";}),_sBlue,false),
        const SizedBox(height:8),
        _searchRow(_sasSearch,(v)=>setState(()=>_sasSearch=v),_sBlue,
          _sasCats[_sasCatIdx]["url"] as String),
        const SizedBox(height:8),
        ..._sasFiltered.map((shop){
          final id=shop["id"] as String;
          final name=shop["name"] as String;
          final pts=(shop["pts"]??0).toString();
          final pop=shop["popular"] as bool?? false;
          final url=shop["url"] as String? ??"https://onlineshopping.flysas.com/nb-NO";
          return _shopRow(name:name,pts:pts,normalPts:null,
            hasCamp:pop,isSel:_sasFavIds.contains(id),accent:_sBlue,accentL:_sBlueL,
            badge:pop?"POPULÆR":null,
            onTap:()=>_toggleSas(id),
            onLink:()=>launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication));
        }),
        const SizedBox(height:8),
        _seeAll("↗ Se alle 400+ butikker på SAS Online Shopping","https://onlineshopping.flysas.com/nb-NO",_sBlue),
      ],
    ]),
  );

  Widget _catRow(List cats,dynamic selId,Function(dynamic) onSel,Color accent,bool showCount)=>
    SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:cats.map((cat){
      final isSel=selId==cat["id"];
      final count=cat["count"]??0;
      return GestureDetector(onTap:()=>onSel(cat["id"]),child:Container(
        margin:const EdgeInsets.only(right:6),
        padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
        decoration:BoxDecoration(
          color:isSel?accent:accent.withOpacity(0.08),
          borderRadius:BorderRadius.circular(20),
          border:Border.all(color:isSel?accent:accent.withOpacity(0.3))),
        child:Row(children:[
          Text(cat["icon"] as String,style:const TextStyle(fontSize:13)),
          const SizedBox(width:4),
          Text(showCount?"${cat["name"]} $count":"${cat["name"]}",
            style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,
              color:isSel?Colors.white:accent)),
        ]),
      ));
    }).toList()));

  Widget _searchRow(String val,Function(String) onChange,Color accent,String openUrl)=>
    Row(children:[
      Expanded(child:TextField(
        onChanged:onChange,
        style:const TextStyle(fontSize:13,color:const Color(0xFFF8FAFC)),
        decoration:InputDecoration(
          hintText:"Søk på butikknavn...",
          hintStyle:TextStyle(color:Colors.grey[500]),
          prefixIcon:Icon(Icons.search,size:16,color:Colors.grey[500]),
          contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(10)),
          isDense:true,filled:true,fillColor:Colors.white,
        ),
      )),
      const SizedBox(width:8),
      GestureDetector(
        onTap:()=>launchUrl(Uri.parse(openUrl),mode:LaunchMode.externalApplication),
        child:Container(padding:const EdgeInsets.all(8),
          decoration:BoxDecoration(color:accent.withOpacity(0.1),borderRadius:BorderRadius.circular(10),border:Border.all(color:accent.withOpacity(0.3))),
          child:Icon(Icons.open_in_new,size:18,color:accent))),
    ]);

  Widget _toggleBtn(bool isPrem,bool isOpen,String count,Color accent,VoidCallback onTap)=>
    GestureDetector(onTap:onTap,child:Container(
      padding:const EdgeInsets.symmetric(vertical:10,horizontal:14),
      decoration:BoxDecoration(
        color:isPrem?accent.withOpacity(0.1):Colors.orange.withOpacity(0.1),
        borderRadius:BorderRadius.circular(10),
        border:Border.all(color:isPrem?accent.withOpacity(0.4):Colors.orange.withOpacity(0.4))),
      child:Row(children:[
        Icon(isPrem?(isOpen?Icons.expand_less:Icons.add):Icons.lock_outline,
          color:isPrem?accent:Colors.orange,size:18),
        const SizedBox(width:8),
        Expanded(child:Text(
          isPrem?(isOpen?"Skjul butikker":"Velg favorittbutikker ($count)"):"Oppgrader for å velge favorittbutikker",
          style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:isPrem?accent:Colors.orange))),
      ]),
    ));

  Widget _shopRow({required String name,required String pts,String? normalPts,
    required bool hasCamp,required bool isSel,required Color accent,required Color accentL,
    String? badge,required VoidCallback onTap,VoidCallback? onLink})=>
    GestureDetector(onTap:onTap,child:Container(
      padding:const EdgeInsets.symmetric(vertical:10,horizontal:12),
      margin:const EdgeInsets.only(bottom:6),
      decoration:BoxDecoration(
        color:isSel?accent.withOpacity(0.12):const Color(0xFF0F1E35),
        borderRadius:BorderRadius.circular(12),
        border:Border.all(color:isSel?accent:const Color(0xFF2F435C))),
      child:Row(children:[
        Container(width:32,height:32,
          decoration:BoxDecoration(
            color:hasCamp?accent.withOpacity(0.15):const Color(0xFF1C3050),
            borderRadius:BorderRadius.circular(8)),
          child:Center(child:Text(name.isNotEmpty?name[0]:"?",
            style:TextStyle(fontSize:14,fontWeight:FontWeight.w800,
              color:hasCamp?accent:const Color(0xFF94A3B8))))),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Flexible(child:Text(name,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:const Color(0xFFF8FAFC)),overflow:TextOverflow.ellipsis)),
            if(badge!=null)...[const SizedBox(width:5),
              Container(padding:const EdgeInsets.symmetric(horizontal:4,vertical:1),
                decoration:BoxDecoration(color:accent,borderRadius:BorderRadius.circular(4)),
                child:Text(badge,style:const TextStyle(fontSize:8,color:Colors.white,fontWeight:FontWeight.w700)))],
          ]),
          Row(children:[
            if(normalPts!=null&&hasCamp)...[
              Text("$normalPts p",style:TextStyle(fontSize:10,color:Colors.grey[400],decoration:TextDecoration.lineThrough)),
              const SizedBox(width:4)],
            Text("$pts p/100kr",style:TextStyle(fontSize:11,
              color:hasCamp?accent:const Color(0xFF94A3B8),
              fontWeight:hasCamp?FontWeight.w700:FontWeight.normal)),
          ]),
        ])),
        if(onLink!=null)GestureDetector(onTap:onLink,child:Padding(
          padding:const EdgeInsets.symmetric(horizontal:8),
          child:Icon(Icons.open_in_new,size:16,color:Colors.grey[400]))),
        Container(width:22,height:22,
          decoration:BoxDecoration(
            color:isSel?accent:Colors.transparent,
            borderRadius:BorderRadius.circular(5),
            border:Border.all(color:isSel?accent:Colors.grey.shade300,width:2)),
          child:isSel?const Icon(Icons.check,size:14,color:Colors.white):null),
      ]),
    ));

  Widget _seeAll(String label,String url,Color color)=>GestureDetector(
    onTap:()=>launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication),
    child:Center(child:Text(label,style:TextStyle(fontSize:12,color:color,fontWeight:FontWeight.w600))));

  Widget _badge(String label,Color color)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
    decoration:BoxDecoration(
      color:color.withOpacity(0.12),borderRadius:BorderRadius.circular(8),
      border:Border.all(color:color.withOpacity(0.3))),
    child:Text(label,style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,letterSpacing:.08,color:color)));

  Widget _h2(String t)=>Text(t,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900));

  Widget _hchip(String label,String value)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
    decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(999)),
    child:Text("$label: $value",style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:11)));

  Widget _alertCard(Map<String,dynamic> item,int index){
    final title=(item["title"]??"-").toString();
    final body=(item["body"]??"-").toString();
    final rate=(item["rate"]??"-").toString();
    final url=(item["url"]??"").toString();
    final isTop=index==0;
    return Container(
      margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        color:isTop?const Color(0xFFECFDF5):Colors.white,
        borderRadius:BorderRadius.circular(16),
        border:Border.all(color:isTop?Colors.green:Colors.grey.shade200)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))),
          if(isTop)const Text("🏆",style:TextStyle(fontSize:20)),
        ]),
        const SizedBox(height:6),
        Text(body,style:const TextStyle(color:const Color(0xFFF8FAFC))),
        const SizedBox(height:6),
        Text("Rate: $rate",style:const TextStyle(fontWeight:FontWeight.w700,color:Colors.green)),
        if(url.isNotEmpty)...[
          const SizedBox(height:8),
          OutlinedButton.icon(
            onPressed:()=>launchUrl(Uri.parse(url)),
            icon:const Icon(Icons.open_in_new,size:16),
            label:const Text("Åpne tilbud")),
        ],
      ]));
  }
}
