#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)" 2>/dev/null || true

cat > "$FILE" << 'DART'
import 'package:flutter/material.dart';

class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _onlyCampaigns = false;
  bool _favFirst = true;
  String _category = 'Alle';

  final Set<String> _fav = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    await Future.delayed(const Duration(milliseconds: 200));

    const cats = ['Elektronikk', 'Reise', 'Klær', 'Helse', 'Hjem'];

    return List.generate(230, (i) {
      final name = "Butikk ${i + 1}";
      final rate = (i % 12) + 1;
      final category = cats[i % cats.length];
      final isCampaign = i % 7 == 0; // litt kampanjer
      return {
        "name": name,
        "rate": rate,
        "category": category,
        "isCampaign": isCampaign,
      };
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> data) {
    final q = _searchCtrl.text.trim().toLowerCase();

    Iterable<Map<String, dynamic>> it = data;

    if (_category != 'Alle') {
      it = it.where((s) => (s["category"] as String) == _category);
    }

    if (_onlyCampaigns) {
      it = it.where((s) => s["isCampaign"] == true);
    }

    if (q.isNotEmpty) {
      it = it.where((s) {
        final name = (s["name"] as String).toLowerCase();
        return name.contains(q);
      });
    }

    final list = it.toList();

    if (_favFirst) {
      list.sort((a, b) {
        final af = _fav.contains(a["name"]);
        final bf = _fav.contains(b["name"]);
        if (af == bf) return 0;
        return af ? -1 : 1;
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("EuroBonus Shopping"),
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

          final data = snap.data ?? [];
          final categories = <String>{
            'Alle',
            ...data.map((e) => e["category"] as String),
          }.toList()
            ..sort((a, b) {
              if (a == 'Alle') return -1;
              if (b == 'Alle') return 1;
              return a.compareTo(b);
            });

          final filtered = _applyFilters(data);

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Søk
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Søk butikk",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
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
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _category = v ?? 'Alle';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

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
                        },
                      ),
                      const SizedBox(width: 8),

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
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Teller
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "${filtered.length} butikker",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final shop = filtered[i];
                      final name = shop["name"] as String;
                      final rate = shop["rate"];
                      final cat = shop["category"] as String;
                      final isCampaign = shop["isCampaign"] == true;
                      final isFav = _fav.contains(name);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(name)),
                              if (isCampaign)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: primary.withOpacity(0.12),
                                  ),
                                  child: Text(
                                    "Kampanje",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text("$rate poeng / 100 kr • $cat"),
                          trailing: IconButton(
                            tooltip: isFav ? 'Fjern favoritt' : 'Legg til favoritt',
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                            onPressed: () {
                              setState(() {
                                if (isFav) {
                                  _fav.remove(name);
                                } else {
                                  _fav.add(name);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
DART

dart format "$FILE" || true
flutter analyze || true

echo "✅ C ferdig: søk + kategori + chips + favoritter + teller."
