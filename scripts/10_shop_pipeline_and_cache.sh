#!/usr/bin/env bash
set -euo pipefail

echo "== [1/6] Backup =="
mkdir -p lib/models lib/services lib/pages

backup() {
  local f="$1"
  if [ -f "$f" ]; then
    cp "$f" "$f.bak.$(date +%s)"
    echo "Backup: $f"
  fi
}

backup lib/models/shop_offer.dart
backup lib/services/eb_repository.dart
backup lib/pages/eb_shopping_page.dart

echo "== [2/6] Skriv datamodell: ShopOffer =="

cat > lib/models/shop_offer.dart <<'DART'
class ShopOffer {
  final String name;
  final double rate; // poeng pr 100 kr
  final String url;
  final String category;
  final bool isCampaign;

  const ShopOffer({
    required this.name,
    required this.rate,
    required this.url,
    required this.category,
    required this.isCampaign,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'rate': rate,
        'url': url,
        'category': category,
        'isCampaign': isCampaign,
      };

  static ShopOffer? fromAny(dynamic v) {
    if (v is! Map) return null;
    final m = Map<String, dynamic>.from(v as Map);

    final name = (m['name'] ?? m['shop'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    final rateRaw = m['rate'] ?? m['points'] ?? m['poeng'] ?? 0;
    final double rate = (rateRaw is num)
        ? rateRaw.toDouble()
        : (double.tryParse(rateRaw.toString()) ?? 0.0);

    final url = (m['url'] ?? m['link'] ?? '').toString().trim();
    final category = (m['category'] ?? m['cat'] ?? 'Alle').toString().trim();
    final isCampaign = (m['isCampaign'] ?? m['campaign'] ?? false) == true;

    return ShopOffer(
      name: name,
      rate: rate,
      url: url,
      category: category.isEmpty ? 'Alle' : category,
      isCampaign: isCampaign,
    );
  }
}
DART

echo "== [3/6] Skriv repository: EbRepository (asset load + normalize + cache) =="

cat > lib/services/eb_repository.dart <<'DART'
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_offer.dart';

class EbRepository {
  // Cache keys
  static const _cacheKey = 'eb_shop_cache_v1';
  static const _cacheTsKey = 'eb_shop_cache_ts_v1';

  // 6 timer er en fin start (kan justeres)
  static const Duration cacheTtl = Duration(hours: 6);

  // Kandidatfiler (i prioritert rekkefølge)
  static const List<String> _assetCandidates = <String>[
    'assets/eb.shopping.pretty.json',
    'assets/eb.shopping.min.json',
    'assets/eb.shopping.json',
    'assets/shops.json',
    'assets/offers.json',
    'assets/offers.min.json',
    'assets/data/offers.json',
    'assets/data/offers.min.json',
  ];

  Future<List<ShopOffer>> fetchShops({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = _readCache(prefs);
      if (cached != null) return cached;
    }

    final raw = await _loadRawFromAssets();
    final shops = _normalize(raw);

    // Cache resultat
    await prefs.setString(_cacheKey, jsonEncode(shops.map((s) => s.toJson()).toList()));
    await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);

    return shops;
  }

  List<ShopOffer>? _readCache(SharedPreferences prefs) {
    final ts = prefs.getInt(_cacheTsKey);
    final s = prefs.getString(_cacheKey);

    if (ts == null || s == null || s.isEmpty) return null;

    final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age > cacheTtl) return null;

    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return null;
      final out = <ShopOffer>[];
      for (final it in decoded) {
        final shop = ShopOffer.fromAny(it);
        if (shop != null) out.add(shop);
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _loadRawFromAssets() async {
    String? jsonStr;

    for (final p in _assetCandidates) {
      try {
        jsonStr = await rootBundle.loadString(p);
        if (jsonStr.trim().isNotEmpty) {
          // Fant en fil som finnes og har innhold
          break;
        }
      } catch (_) {
        // ignore - prøv neste
      }
    }

    if (jsonStr == null || jsonStr.trim().isEmpty) {
      // Tomt -> tom liste
      return const <dynamic>[];
    }

    return jsonDecode(jsonStr);
  }

  List<ShopOffer> _normalize(dynamic decoded) {
    // Godtar både:
    // 1) { "shops": [ ... ] }
    // 2) [ ... ]
    List<dynamic> rawList;

    if (decoded is Map && decoded['shops'] is List) {
      rawList = List<dynamic>.from(decoded['shops'] as List);
    } else if (decoded is List) {
      rawList = List<dynamic>.from(decoded);
    } else {
      rawList = const <dynamic>[];
    }

    final out = <ShopOffer>[];
    final seen = <String>{};

    for (final it in rawList) {
      final shop = ShopOffer.fromAny(it);
      if (shop == null) continue;

      // dedupe på name + url
      final key = '${shop.name}||${shop.url}';
      if (seen.contains(key)) continue;
      seen.add(key);

      out.add(shop);
    }

    // Stabil sort: høy rate først, ellers alfabetisk
    out.sort((a, b) {
      final r = b.rate.compareTo(a.rate);
      if (r != 0) return r;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return out;
  }
}
DART

echo "== [4/6] Oppdater EbShoppingPage til å bruke modellen + repo + prefs =="

cat > lib/pages/eb_shopping_page.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/shop_offer.dart';
import '../services/eb_repository.dart';

class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {
  final EbRepository _repo = EbRepository();

  late Future<List<ShopOffer>> _futureShops;

  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'Alle';
  bool _onlyCampaigns = false;
  bool _favFirst = false;
  final Set<String> _fav = <String>{};

  @override
  void initState() {
    super.initState();
    _futureShops = _repo.fetchShops();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fav
        ..clear()
        ..addAll(prefs.getStringList('eb_shop_fav') ?? const <String>[]);
      _onlyCampaigns = prefs.getBool('eb_shop_only_campaigns') ?? false;
      _favFirst = prefs.getBool('eb_shop_fav_first') ?? false;
      _category = prefs.getString('eb_shop_category') ?? 'Alle';
      _searchCtrl.text = prefs.getString('eb_shop_query') ?? '';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('eb_shop_fav', _fav.toList());
    await prefs.setBool('eb_shop_only_campaigns', _onlyCampaigns);
    await prefs.setBool('eb_shop_fav_first', _favFirst);
    await prefs.setString('eb_shop_category', _category);
    await prefs.setString('eb_shop_query', _searchCtrl.text.trim());
  }

  List<ShopOffer> _applyFilters(List<ShopOffer> data) {
    final q = _searchCtrl.text.trim().toLowerCase();

    Iterable<ShopOffer> it = data;

    if (_category != 'Alle') {
      it = it.where((s) => s.category == _category);
    }

    if (_onlyCampaigns) {
      it = it.where((s) => s.isCampaign);
    }

    if (q.isNotEmpty) {
      it = it.where((s) => s.name.toLowerCase().contains(q));
    }

    final list = it.toList();

    if (_favFirst) {
      list.sort((a, b) {
        final af = _fav.contains(a.name);
        final bf = _fav.contains(b.name);
        if (af != bf) return af ? -1 : 1;
        // beholder “rate desc, name asc” feel
        final r = b.rate.compareTo(a.rate);
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    return list;
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EuroBonus Shopping'),
        actions: [
          IconButton(
            tooltip: 'Oppdater',
            onPressed: () {
              setState(() {
                _futureShops = _repo.fetchShops(forceRefresh: true);
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<ShopOffer>>(
        future: _futureShops,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? const <ShopOffer>[];
          final categories = <String>{
            'Alle',
            ...data.map((s) => s.category).where((c) => c.trim().isNotEmpty),
          }.toList()
            ..sort((a, b) {
              if (a == 'Alle') return -1;
              if (b == 'Alle') return 1;
              return a.compareTo(b);
            });

          // fallback hvis kategori ikke finnes lenger
          if (!categories.contains(_category)) {
            _category = 'Alle';
          }

          final filtered = _applyFilters(data);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Søk butikk…',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _savePrefs();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Kategori + chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _category = v ?? 'Alle');
                              _savePrefs();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilterChip(
                          selectedColor: primary,
                          backgroundColor: Colors.grey.shade200,
                          checkmarkColor: Colors.white,
                          side: const BorderSide(color: Colors.black12),
                          label: Text(
                            'Kun kampanjer',
                            style: TextStyle(
                              color: _onlyCampaigns ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: _onlyCampaigns,
                          onSelected: (v) {
                            setState(() => _onlyCampaigns = v);
                            _savePrefs();
                          },
                        ),
                        const SizedBox(width: 10),
                        FilterChip(
                          selectedColor: primary,
                          backgroundColor: Colors.grey.shade200,
                          checkmarkColor: Colors.white,
                          side: const BorderSide(color: Colors.black12),
                          label: Text(
                            'Favoritter først',
                            style: TextStyle(
                              color: _favFirst ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: _favFirst,
                          onSelected: (v) {
                            setState(() => _favFirst = v);
                            _savePrefs();
                          },
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${filtered.length} butikker',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final s = filtered[i];
                        final isFav = _fav.contains(s.name);

                        return ListTile(
                          leading: Icon(
                            s.isCampaign ? Icons.local_offer : Icons.store,
                            color: s.isCampaign ? primary : null,
                          ),
                          title: Text(s.name),
                          subtitle: Text(
                            '${s.rate.toStringAsFixed(s.rate == s.rate.roundToDouble() ? 0 : 1)} poeng / 100 kr'
                            '${s.category.isNotEmpty && s.category != 'Alle' ? ' • ${s.category}' : ''}'
                            '${s.isCampaign ? ' • Kampanje' : ''}',
                          ),
                          trailing: IconButton(
                            tooltip: isFav ? 'Fjern favoritt' : 'Legg til favoritt',
                            icon: Icon(isFav ? Icons.star : Icons.star_border),
                            onPressed: () {
                              setState(() {
                                if (isFav) {
                                  _fav.remove(s.name);
                                } else {
                                  _fav.add(s.name);
                                }
                              });
                              _savePrefs();
                            },
                          ),
                          onTap: s.url.isEmpty ? null : () => _openUrl(s.url),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
DART

echo "== [5/6] Format + analyze =="
dart format lib/models/shop_offer.dart lib/services/eb_repository.dart lib/pages/eb_shopping_page.dart
flutter analyze

echo "== [6/6] Ferdig ✅ =="
