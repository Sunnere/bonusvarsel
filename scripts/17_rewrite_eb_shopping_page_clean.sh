#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
mkdir -p lib/pages
[ -f "$FILE" ] && cp "$FILE" "$FILE.bak.$(date +%s)" || true

cat > "$FILE" <<'DART'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bonusvarsel/models/shop_offer.dart';
import 'package:bonusvarsel/services/eb_repository.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {
  static const int freeLimit = 30;
  static const String _favKey = 'eb_shopping_favs';

  final EBRepository _repo = EBRepository();
  final PremiumService _premiumSvc = const PremiumService();

  late Future<List<ShopOffer>> _futureShops;

  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'Alle';
  bool _onlyCampaigns = false;
  bool _favFirst = false;
  bool _sortByRate = false;

  bool _isPremium = false;
  final Set<String> _fav = <String>{};

  @override
  void initState() {
    super.initState();
    _futureShops = _repo.fetchShops();

    _loadFavs();
    _premiumSvc.getIsPremium().then((v) {
      if (!mounted) return;
      setState(() => _isPremium = v);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favKey) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _fav
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _saveFavs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favKey, _fav.toList());
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url.trim());
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  List<ShopOffer> _applyFilters(List<ShopOffer> data) {
    final q = _searchCtrl.text.trim().toLowerCase();

    Iterable<ShopOffer> it = data;

    if (_category != 'Alle') {
      it = it.where((s) => s.category.trim() == _category);
    }

    if (_onlyCampaigns) {
      it = it.where((s) => s.isCampaign == true);
    }

    if (q.isNotEmpty) {
      it = it.where((s) => s.name.toLowerCase().contains(q));
    }

    final list = it.toList();

    // Favoritter først
    if (_favFirst) {
      list.sort((a, b) {
        final af = _fav.contains(a.name);
        final bf = _fav.contains(b.name);
        if (af != bf) return af ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    // Sorter etter rate (premium feature)
    if (_sortByRate) {
      list.sort((a, b) {
        final r = b.rate.compareTo(a.rate);
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    return list;
  }

  Widget _upgradeBanner(BuildContext context, int hiddenCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hiddenCount > 0
                  ? 'Gratis: viser $freeLimit butikker. $hiddenCount skjult. Oppgrader for å se alle + flere filter.'
                  : 'Oppgrader for å låse opp premium-funksjoner.',
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium kommer (placeholder)')),
              );
            },
            child: const Text('Oppgrader'),
          ),
        ],
      ),
    );
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
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Feil: ${snap.error}'),
            );
          }

          final data = snap.data ?? <ShopOffer>[];
          final filtered = _applyFilters(data);

          // Categories (unik) + safe dropdown-value
          final categoriesSet = <String>{
            'Alle',
            ...data
                .map((e) => e.category.trim())
                .where((c) => c.isNotEmpty),
          };
          final categories = categoriesSet.toList()..sort();
          categories.remove('Alle');
          categories.insert(0, 'Alle');

          final safeCategory = categories.contains(_category) ? _category : 'Alle';
          if (safeCategory != _category) {
            // viktig: ikke setState her (build-loop). Bare bruk safeCategory i dropdown value.
          }

          // Gating
          final isGated = !_isPremium && filtered.length > freeLimit;
          final visible = (!_isPremium && filtered.length > freeLimit)
              ? filtered.take(freeLimit).toList()
              : filtered;

          return ListView(
            children: [
              const SizedBox(height: 10),

              // Søk
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Søk butikk',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
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
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: safeCategory,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${filtered.length} butikker',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Kampanjer'),
                      selected: _onlyCampaigns,
                      onSelected: (v) => setState(() => _onlyCampaigns = v),
                      selectedColor: primary.withValues(alpha: 0.20),
                    ),
                    FilterChip(
                      label: const Text('Favoritter først'),
                      selected: _favFirst,
                      onSelected: (v) => setState(() => _favFirst = v),
                      selectedColor: primary.withValues(alpha: 0.20),
                    ),
                    FilterChip(
                      label: const Text('Sorter på rate (Premium)'),
                      selected: _sortByRate,
                      onSelected: (v) {
                        if (!_isPremium) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Premium: sorter på rate')),
                          );
                          return;
                        }
                        setState(() => _sortByRate = v);
                      },
                      selectedColor: primary.withValues(alpha: 0.20),
                    ),
                  ],
                ),
              ),

              if (isGated) _upgradeBanner(context, filtered.length - freeLimit),

              const SizedBox(height: 8),

              // Liste
              for (final offer in visible)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      offer.isCampaign ? Icons.local_fire_department : Icons.store,
                      color: offer.isCampaign ? primary : null,
                    ),
                    title: Text(offer.name),
                    subtitle: Text(
                      '${offer.rate.toStringAsFixed(1)} poeng'
                      '${offer.category.trim().isNotEmpty ? ' • ${offer.category}' : ''}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Favoritt',
                      icon: Icon(
                        _fav.contains(offer.name) ? Icons.star : Icons.star_border,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_fav.contains(offer.name)) {
                            _fav.remove(offer.name);
                          } else {
                            _fav.add(offer.name);
                          }
                        });
                        _saveFavs();
                      },
                    ),
                    onTap: () => _openUrl(offer.url),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
DART

dart format "$FILE"
flutter analyze
