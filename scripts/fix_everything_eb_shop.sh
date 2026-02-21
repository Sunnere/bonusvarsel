#!/usr/bin/env bash
set -euo pipefail

echo "== [1/5] Backup (hvis filer finnes) =="
[ -f lib/pages/eb_shopping_page.dart ] && cp lib/pages/eb_shopping_page.dart lib/pages/eb_shopping_page.bak.$(date +%s).dart || true
[ -f assets/eb.shopping.pretty.json ] && cp assets/eb.shopping.pretty.json assets/eb.shopping.pretty.bak.$(date +%s).json || true

echo "== [2/5] Lag pretty JSON (fra min) =="
python - <<'PY'
import json
from pathlib import Path

src_candidates = [
  Path("assets/eb.shopping.min.json"),
  Path("assets/eb_shopping.min.json"),
  Path("assets/eb.shopping.json"),
  Path("assets/eb_shopping.json"),
]
src = next((p for p in src_candidates if p.exists()), None)
if not src:
  raise SystemExit("Fant ingen av disse filene: " + ", ".join(map(str, src_candidates)))

dst = Path("assets/eb.shopping.pretty.json")

data = json.loads(src.read_text(encoding="utf-8"))
dst.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"OK: {src} -> {dst}")
PY

echo "== [3/5] Skriv clean eb_shopping_page.dart =="
cat > lib/pages/eb_shopping_page.dart <<'DART'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {
  bool _onlyCampaigns = false;
  bool _favFirst = true;
  String _category = 'Alle';
  final TextEditingController _searchCtrl = TextEditingController();

  /// Enkel parsing: støtter både
  /// { shops: [...] } og { items: [...] } og ren liste [...]
  Future<List<Map<String, dynamic>>> _load() async {
    final raw = await rootBundle.loadString('assets/eb.shopping.pretty.json');
    final decoded = json.decode(raw);

    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['shops'] is List) {
      list = decoded['shops'] as List;
    } else if (decoded is Map && decoded['items'] is List) {
      list = decoded['items'] as List;
    } else {
      // fallback: prøv typiske keys
      for (final k in ['data', 'results', 'partners']) {
        if (decoded is Map && decoded[k] is List) {
          list = decoded[k] as List;
          break;
        }
      }
      list = (decoded is Map ? (decoded.values.whereType<List>().isNotEmpty ? decoded.values.whereType<List>().first : <dynamic>[]) : <dynamic>[]);
    }

    // Normaliser til felt vi bruker i UI
    return list.map<Map<String, dynamic>>((e) {
      final m = (e is Map) ? e : <String, dynamic>{};

      final name = (m['name'] ?? m['title'] ?? m['merchant'] ?? '').toString().trim();
      final url = (m['url'] ?? m['link'] ?? m['href'] ?? '').toString().trim();

      // rate kan hete mange ting
      final rateRaw = m['rate'] ?? m['points'] ?? m['value'] ?? m['earn'] ?? 0;

      num rate;
      if (rateRaw is num) {
        rate = rateRaw;
      } else {
        final parsed = num.tryParse(rateRaw.toString().replaceAll(',', '.'));
        rate = parsed ?? 0;
      }

      // campaign/boost kan hete mange ting
      final campaign = (m['campaign'] ?? m['isCampaign'] ?? m['boost'] ?? m['promo'] ?? false) == true;

      // kategori kan være string eller liste
      String category = 'Alle';
      final catRaw = m['category'] ?? m['categories'] ?? m['type'];
      if (catRaw is String && catRaw.trim().isNotEmpty) category = catRaw.trim();
      if (catRaw is List && catRaw.isNotEmpty) category = catRaw.first.toString();

      return {
        'name': name.isEmpty ? 'Ukjent butikk' : name,
        'url': url,
        'rate': rate,
        'campaign': campaign,
        'category': category.isEmpty ? 'Alle' : category,
      };
    }).toList();
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('Fant ingen data'));
          }

          final all = snap.data!;

          final categories = <String>{'Alle'};
          for (final s in all) {
            categories.add((s['category'] ?? 'Alle').toString());
          }
          final categoryList = categories.toList()..sort();

          var shops = all;

          // Filter: kategori
          if (_category != 'Alle') {
            shops = shops.where((s) => (s['category'] ?? 'Alle').toString() == _category).toList();
          }

          // Filter: kampanjer
          if (_onlyCampaigns) {
            shops = shops.where((s) => s['campaign'] == true).toList();
          }

          // Filter: søk
          final q = _searchCtrl.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            shops = shops.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(q)).toList();
          }

          // Sortering
          if (_favFirst) {
            shops.sort((a, b) => (b['rate'] as num).compareTo(a['rate'] as num));
          }

          return Column(
            children: [
              const SizedBox(height: 12),

              // Søk
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Søk butikk',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 10),

              // Kategori + chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // kategori dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: categoryList
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v ?? 'Alle'),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // chip: kun kampanjer
                    FilterChip(
                      label: Text(
                        'Kun kampanjer',
                        style: TextStyle(
                          color: _onlyCampaigns ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: _onlyCampaigns,
                      onSelected: (v) => setState(() => _onlyCampaigns = v),
                      selectedColor: primary,
                      backgroundColor: Colors.grey.shade200,
                      checkmarkColor: Colors.white,
                      side: BorderSide(color: Colors.black12),
                    ),
                    const SizedBox(width: 10),

                    // chip: høyest poeng først
                    FilterChip(
                      label: Text(
                        'Favoritter først',
                        style: TextStyle(
                          color: _favFirst ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: _favFirst,
                      onSelected: (v) => setState(() => _favFirst = v),
                      selectedColor: primary,
                      backgroundColor: Colors.grey.shade200,
                      checkmarkColor: Colors.white,
                      side: BorderSide(color: Colors.black12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // statuslinje
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Viser ${shops.length} av ${all.length}'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _category = 'Alle';
                          _onlyCampaigns = false;
                          _favFirst = true;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Nullstill'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // liste
              Expanded(
                child: ListView.builder(
                  itemCount: shops.length,
                  itemBuilder: (context, i) {
                    final shop = shops[i];
                    final name = (shop['name'] ?? 'Ukjent butikk').toString();
                    final url = (shop['url'] ?? '').toString();
                    final rate = shop['rate'] as num;
                    final isCampaign = shop['campaign'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text('${rate.toString()} poeng per 100 kr'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCampaign) const Icon(Icons.local_offer, color: Colors.green),
                            const SizedBox(width: 10),
                            IconButton(
                              tooltip: 'Åpne',
                              onPressed: () => _openUrl(url),
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
          );
        },
      ),
    );
  }
}
DART

echo "== [4/5] Format + analyze =="
dart format lib/pages/eb_shopping_page.dart >/dev/null
flutter analyze || true

echo "== [5/5] Kjør web =="
kill $(lsof -ti :8080) 2>/dev/null || true
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
