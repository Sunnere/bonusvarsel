#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
mkdir -p "$(dirname "$FILE")"
[ -f "$FILE" ] && cp "$FILE" "$FILE.bak.$(date +%s)" || true

cat > "$FILE" <<'DART'
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {
  late final Future<List<Map<String, dynamic>>> _futureShops;

  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'Alle';
  bool _onlyCampaigns = false;
  bool _favFirst = false;
  final Set<String> _fav = <String>{};

  @override
  void initState() {
    super.initState();
    _futureShops = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final fav = prefs.getStringList('eb_shop_fav') ?? const <String>[];
    final only = prefs.getBool('eb_shop_only_campaigns') ?? false;
    final favFirst = prefs.getBool('eb_shop_fav_first') ?? false;
    final cat = prefs.getString('eb_shop_category') ?? 'Alle';
    final q = prefs.getString('eb_shop_query') ?? '';

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

  Future<List<Map<String, dynamic>>> _load() async {
    // last inn prefs først
    await _loadPrefs();

    // prøv flere filnavn (i tilfelle du endrer asset-navn)
    const candidates = <String>[
      'assets/eb.shopping.pretty.json',
      'assets/eb.shopping.min.json',
      'assets/eb.shopping.json',
      'assets/data/eb.shopping.pretty.json',
      'assets/data/eb.shopping.min.json',
      'assets/data/eb.shopping.json',
    ];

    String? jsonStr;
    for (final p in candidates) {
      try {
        jsonStr = await rootBundle.loadString(p);
        break;
      } catch (_) {}
    }

    if (jsonStr == null) {
      // fail-safe: tom liste
      return <Map<String, dynamic>>[];
    }

    final decoded = json.decode(jsonStr);
    final List<dynamic> rawList;
    if (decoded is Map && decoded['shops'] is List) {
      rawList = (decoded['shops'] as List).cast<dynamic>();
    } else if (decoded is List) {
      rawList = decoded.cast<dynamic>();
    } else {
      rawList = const <dynamic>[];
    }

    // normaliser
    final out = <Map<String, dynamic>>[];
    for (final it in rawList) {
      if (it is! Map) continue;
      final m = Map<String, dynamic>.from(it as Map);

      final name = (m['name'] ?? m['shop'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final rateRaw = m['rate'] ?? m['points'] ?? m['poeng'];
      final rateNum = (rateRaw is num)
          ? rateRaw.toDouble()
          : double.tryParse(rateRaw?.toString() ?? '') ?? 0.0;

      final url = (m['url'] ?? m['link'] ?? '').toString().trim();
      final category = (m['category'] ?? m['cat'] ?? 'Alle').toString().trim();
      final isCampaignRaw = m['isCampaign'] ?? m['campaign'] ?? m['is_campaign'];
      final isCampaign = (isCampaignRaw is bool)
          ? isCampaignRaw
          : (isCampaignRaw?.toString().toLowerCase() == 'true');

      out.add(<String, dynamic>{
        'name': name,
        'rate': rateNum,
        'url': url,
        'category': category.isEmpty ? 'Alle' : category,
        'isCampaign': isCampaign,
      });
    }

    return out;
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> data) {
    final q = _searchCtrl.text.trim().toLowerCase();

    Iterable<Map<String, dynamic>> it = data;

    if (_category != 'Alle') {
      it = it.where((s) => (s['category'] as String) == _category);
    }

    if (_onlyCampaigns) {
      it = it.where((s) => s['isCampaign'] == true);
    }

    if (q.isNotEmpty) {
      it = it.where((s) {
        final name = (s['name'] as String).toLowerCase();
        return name.contains(q);
      });
    }

    final list = it.toList();

    // favoritter først (stable)
    if (_favFirst) {
      list.sort((a, b) {
        final af = _fav.contains(a['name']);
        final bf = _fav.contains(b['name']);
        if (af == bf) return 0;
        return af ? -1 : 1;
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
            onPressed: () => setState(() {
              _futureShops = _load();
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureShops,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data ?? const <Map<String, dynamic>>[];
          final filtered = _applyFilters(data);

          // kategori-liste
          final cats = <String>{
            'Alle',
            ...data.map((e) => (e['category'] as String)),
          }.toList()
            ..sort();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  // Søk
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

                  // Kategori + chips + count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // count (grønn)
                        Text(
                          '${filtered.length} butikker',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Kategori',
                            ),
                            items: cats
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() => _category = v ?? 'Alle');
                              _savePrefs();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Kun kampanjer
                        FilterChip(
                          selectedColor: primary,
                          backgroundColor: Colors.grey.shade200,
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: Colors.black12),
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

                        const SizedBox(width: 8),

                        // Favoritter først
                        FilterChip(
                          selectedColor: primary,
                          backgroundColor: Colors.grey.shade200,
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: Colors.black12),
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

                  const SizedBox(height: 10),

                  // liste
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final shop = filtered[i];
                        final name = shop['name'] as String;
                        final rate = shop['rate'] as double;
                        final url = shop['url'] as String;
                        final isCampaign = shop['isCampaign'] == true;
                        final isFav = _fav.contains(name);

                        return ListTile(
                          leading: Icon(
                            isCampaign ? Icons.local_fire_department : Icons.store,
                          ),
                          title: Text(name),
                          subtitle: Text('${rate.toStringAsFixed(0)} poeng / 100 kr'),
                          trailing: IconButton(
                            tooltip: isFav ? 'Fjern favoritt' : 'Legg til favoritt',
                            onPressed: () {
                              setState(() {
                                if (isFav) {
                                  _fav.remove(name);
                                } else {
                                  _fav.add(name);
                                }
                              });
                              _savePrefs();
                            },
                            icon: Icon(isFav ? Icons.star : Icons.star_border),
                          ),
                          onTap: url.isEmpty ? null : () => _openUrl(url),
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

dart format "$FILE" >/dev/null
echo "✅ Skrev + formaterte: $FILE"
