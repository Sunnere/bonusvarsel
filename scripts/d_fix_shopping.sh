#!/usr/bin/env bash
set -euo pipefail

# 1) Repository som tåler at JSON er { shops: [...], campaigns: [...] }
cat > lib/services/eb_repository.dart <<'DART'
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class EbRepository {
  static const _cacheKey = 'eb_shops_cache_v2';
  static const _cacheTsKey = 'eb_shops_cache_ts_v2';
  static const _ttlMs = 6 * 60 * 60 * 1000; // 6 timer

  Future<Map<String, dynamic>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheTsKey);
    final cached = prefs.getString(_cacheKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cached != null && ts != null && (now - ts) < _ttlMs) {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) return decoded;
    }

    final text = await rootBundle.loadString('assets/eb.shopping.min.json');
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Uventet JSON-format i eb.shopping.min.json (forventet Map).');
    }

    await prefs.setString(_cacheKey, jsonEncode(decoded));
    await prefs.setInt(_cacheTsKey, now);
    return decoded;
  }

  // Normaliserer ett shop-objekt til en stabil form som UI kan bruke.
  Map<String, dynamic> _normShop(
    Map<String, dynamic> s, {
    required bool isCampaign,
  }) {
    String name =
        (s['name'] ?? s['store'] ?? s['title'] ?? s['merchant'] ?? '').toString().trim();
    if (name.isEmpty) name = 'Ukjent butikk';

    // rate / points kan hete litt forskjellig – vi prøver flere.
    num rateNum = 0;
    final candidates = [
      s['rate'],
      s['points'],
      s['pointsPer100'],
      s['points_per_100'],
      s['earnRate'],
      s['earn_rate'],
      s['value'],
    ];
    for (final v in candidates) {
      if (v == null) continue;
      if (v is num) {
        rateNum = v;
        break;
      }
      final parsed = num.tryParse(v.toString());
      if (parsed != null) {
        rateNum = parsed;
        break;
      }
    }

    String url =
        (s['url'] ?? s['link'] ?? s['href'] ?? s['targetUrl'] ?? s['target_url'] ?? '')
            .toString()
            .trim();

    // Kategori
    String category = (s['category'] ?? s['segment'] ?? s['kind'] ?? 'Alle').toString();
    if (category.trim().isEmpty) category = 'Alle';

    // id
    final id = (s['id'] ?? s['shopId'] ?? s['shop_id'] ?? s['merchantId'] ?? name).toString();

    return <String, dynamic>{
      'id': id,
      'name': name,
      'rate': rateNum,
      'url': url,
      'category': category,
      'isCampaign': isCampaign,
      'raw': s,
    };
  }

  Future<List<Map<String, dynamic>>> loadShops() async {
    final raw = await _loadRaw();

    final shopsRaw = raw['shops'];
    final campaignsRaw = raw['campaigns'];

    if (shopsRaw is! List) {
      throw StateError('Fant ikke "shops" som liste i eb.shopping.min.json');
    }

    // Finn hvilke shops som er i kampanje.
    final Set<String> campaignShopIds = {};
    if (campaignsRaw is List) {
      for (final c in campaignsRaw) {
        if (c is Map) {
          final cid = (c['shopId'] ?? c['shop_id'] ?? c['id'] ?? c['merchantId'])?.toString();
          if (cid != null && cid.trim().isNotEmpty) campaignShopIds.add(cid.trim());
        }
      }
    }

    final out = <Map<String, dynamic>>[];
    for (final it in shopsRaw) {
      if (it is Map) {
        final m = Map<String, dynamic>.from(it as Map);
        final sid = (m['id'] ?? m['shopId'] ?? m['shop_id'] ?? m['merchantId'] ?? '').toString();
        final isCamp = campaignShopIds.contains(sid);
        out.add(_normShop(m, isCampaign: isCamp));
      }
    }
    return out;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTsKey);
  }
}
DART

# 2) Shopping-side som faktisk bruker EbRepository + viser riktige felter
cat > lib/pages/eb_shopping_page.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonusvarsel/services/eb_repository.dart';

class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final EbRepository _repo = EbRepository();

  late Future<List<Map<String, dynamic>>> _future;

  // prefs
  final Set<String> _fav = {};
  bool _onlyCampaigns = false;
  bool _favFirst = true;
  String _category = 'Alle';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    return _repo.loadShops();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final fav = prefs.getStringList('eb_shop_fav') ?? const [];
    final only = prefs.getBool('eb_shop_only_campaigns') ?? false;
    final favFirst = prefs.getBool('eb_shop_fav_first') ?? true;
    final cat = prefs.getString('eb_shop_category') ?? 'Alle';
    final q = prefs.getString('eb_shop_query') ?? '';

    if (!mounted) return;
    setState(() {
      _fav
        ..clear()
        ..addAll(fav);
      _onlyCampaigns = only;
      _favFirst = favFirst;
      _category = cat;
      _searchCtrl.text = q;
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

  Future<void> _refresh() async {
    await _repo.clearCache();
    if (!mounted) return;
    setState(() => _future = _load());
  }

  Future<void> _open(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> shops) {
    final q = _searchCtrl.text.trim().toLowerCase();

    List<Map<String, dynamic>> out = shops.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final url = (s['url'] ?? '').toString().toLowerCase();
      final cat = (s['category'] ?? 'Alle').toString();

      if (_onlyCampaigns && (s['isCampaign'] != true)) return false;
      if (_category != 'Alle' && cat != _category) return false;

      if (q.isEmpty) return true;
      return name.contains(q) || url.contains(q);
    }).toList();

    if (_favFirst) {
      out.sort((a, b) {
        final af = _fav.contains(a['id'].toString());
        final bf = _fav.contains(b['id'].toString());
        if (af == bf) return 0;
        return af ? -1 : 1;
      });
    }

    return out;
  }

  Set<String> _categories(List<Map<String, dynamic>> shops) {
    final set = <String>{'Alle'};
    for (final s in shops) {
      final c = (s['category'] ?? 'Alle').toString().trim();
      if (c.isNotEmpty) set.add(c);
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EuroBonus Shopping'),
        actions: [
          IconButton(
            tooltip: 'Oppdater',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Kunne ikke laste shopping-tilbud.\n\n${snap.error}'),
            );
          }

          final all = snap.data ?? const [];
          final cats = _categories(all).toList()..sort();
          final filtered = _applyFilters(all);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Søk butikk',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _savePrefs();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: cats
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _category = v);
                            _savePrefs();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilterChip(
                        label: const Text('Kun kampanjer'),
                        selected: _onlyCampaigns,
                        onSelected: (v) {
                          setState(() => _onlyCampaigns = v);
                          _savePrefs();
                        },
                      ),
                      const SizedBox(width: 10),
                      FilterChip(
                        label: const Text('Favoritter først'),
                        selected: _favFirst,
                        onSelected: (v) {
                          setState(() => _favFirst = v);
                          _savePrefs();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Viser ${filtered.length} av ${all.length}'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                            _onlyCampaigns = false;
                            _favFirst = true;
                            _category = 'Alle';
                          });
                          _savePrefs();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Nullstill'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final s = filtered[i];
                        final id = s['id'].toString();
                        final name = (s['name'] ?? 'Ukjent butikk').toString();
                        final rate = (s['rate'] ?? 0).toString();
                        final url = (s['url'] ?? '').toString();
                        final isFav = _fav.contains(id);

                        return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text('$rate poeng per 100 kr'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Favoritt',
                                  onPressed: () {
                                    setState(() {
                                      if (isFav) {
                                        _fav.remove(id);
                                      } else {
                                        _fav.add(id);
                                      }
                                    });
                                    _savePrefs();
                                  },
                                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                                ),
                                IconButton(
                                  tooltip: 'Åpne',
                                  onPressed: () => _open(url),
                                  icon: const Icon(Icons.open_in_new),
                                ),
                              ],
                            ),
                          ),
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

# 3) Format + restart
dart format lib/services/eb_repository.dart lib/pages/eb_shopping_page.dart

echo "✅ Shopping fikset: repo leser shops/campaigns + UI viser name/rate/url."
