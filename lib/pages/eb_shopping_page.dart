import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bonusvarsel/models/shop_offer.dart';
import 'package:bonusvarsel/services/eb_repository.dart';
import 'package:bonusvarsel/services/premium_service.dart';

// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings, unused_element
class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

class _EbShoppingPageState extends State<EbShoppingPage> {
  // removed unused _favKey

  final EbRepository _repo = EbRepository();
  final PremiumService _premiumSvc = const PremiumService();

  late Future<List<ShopOffer>> _futureShops;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  // Filters / prefs
  String _category = 'Alle';
  bool _onlyCampaigns = false;
  bool _favFirst = false;
  bool _sortByRate = false;

  // Premium state
  bool _isPremium = false;
  bool _showBadges = true;
  int _freeLimit = 30;

  // Simple filter cache (perf)
  String _filterCacheKey = '';
  List<String> _categoriesCache = const <String>['Alle'];
  int _categoriesCacheSourceLen = -1;
  int _filterCacheSourceLen = -1;
  List<ShopOffer> _filterCache = const <ShopOffer>[];

  @override
  void initState() {
    super.initState();
    _futureShops = _repo.fetchShops(forceRefresh: false);

    // Load premium/debug prefs
    _loadPremiumPrefs();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadPremiumPrefs() async {
    final isPrem = await _premiumSvc.getIsPremium();
    if (!mounted) return;
    final showBadges = await _premiumSvc.getShowBadges(fallback: true);
    if (!mounted) return;
    final freeLimit = await _premiumSvc.getFreeLimit(fallback: 30);
    if (!mounted) return;

    if (!mounted) return;
    setState(() {
      _isPremium = isPrem;
      _showBadges = showBadges;
      _freeLimit = freeLimit;
    });
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        // just rebuild; filter uses controller text
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!mounted) return;
  }

  // ---- Robust helpers: works whether ShopOffer is a class or you later swap to Map ----
  String _nameOf(Object it) {
    if (it is Map) return (it['name'] ?? it['shop'] ?? '').toString();
    final d = it as dynamic;
    return (d.name ?? d.shop ?? '').toString();
  }

  double _rateOf(Object it) {
    if (it is Map) {
      final v = it['rate'] ?? it['points'] ?? it['poeng'];
      return (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    }
    final d = it as dynamic;
    final v = d.rate ?? d.points ?? d.poeng;
    return (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
  }

  String _urlOf(Object it) {
    if (it is Map) return (it['url'] ?? it['link'] ?? '').toString();
    final d = it as dynamic;
    return (d.url ?? d.link ?? '').toString();
  }

  String _categoryOf(Object it) {
    if (it is Map) {
      return (it['category'] ?? it['kategori'] ?? 'Ukjent').toString();
    }

    final d = it as dynamic;
    return (d.category ?? d.kategori ?? 'Ukjent').toString();
  }

  bool _isCampaignOf(Object it) {
    if (it is Map) return (it['isCampaign'] ?? it['campaign'] ?? false) == true;
    final d = it as dynamic;
    return (d.isCampaign ?? d.campaign ?? false) == true;
  }

  // ---- UI helpers ----
  List<String> _getCategoriesCached(List<ShopOffer> data) {
    if (_categoriesCacheSourceLen == data.length &&
        _categoriesCache.isNotEmpty) {
      return _categoriesCache;
    }
    final set = <String>{'Alle'};
    for (final it in data) {
      final c = _categoryOf(it).trim();
      if (c.isNotEmpty) set.add(c);
    }
    final out = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _categoriesCache = out;
    _categoriesCacheSourceLen = data.length;
    return out;
  }

  List<String> _buildCategories(List<ShopOffer> data) {
    final set = <String>{};
    for (final s in data) {
      final c = _categoryOf(s).trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    // Ensure 'Alle' exists exactly once and is first
    return <String>['Alle', ...list.where((x) => x != 'Alle')];
  }

  String _filterKey(int sourceLen) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return '$sourceLen|q=$q|cat=$_category|camp=$_onlyCampaigns|favFirst=$_favFirst|sort=$_sortByRate|prem=$_isPremium|limit=$_freeLimit';
  }

  List<ShopOffer> _applyFilters(List<ShopOffer> data) {
    final q = _searchCtrl.text.trim().toLowerCase();

    // Bygger en stabil cache-key uten Dart $-interpolasjon (robust i scripts)
    final key = data.length.toString() +
        '|' +
        q +
        '|' +
        _category +
        '|' +
        (_onlyCampaigns ? '1' : '0') +
        '|' +
        (_favFirst ? '1' : '0') +
        '|' +
        (_sortByRate ? '1' : '0') +
        '|' +
        (_isPremium ? '1' : '0') +
        '|' +
        _freeLimit.toString();

    if (_filterCacheKey == key &&
        _filterCacheSourceLen == data.length &&
        _filterCache.isNotEmpty) {
      return _filterCache;
    }

    var list = data.toList();

    if (q.isNotEmpty) {
      list = list.where((it) => _nameOf(it).toLowerCase().contains(q)).toList();
    }

    if (_category != 'Alle') {
      list = list.where((it) => _categoryOf(it) == _category).toList();
    }

    if (_onlyCampaigns) {
      list = list.where((it) => _isCampaignOf(it)).toList();
    }

    if (_sortByRate) {
      list.sort((a, b) {
        final r = _rateOf(b).compareTo(_rateOf(a));
        if (r != 0) return r;
        return _nameOf(a).toLowerCase().compareTo(_nameOf(b).toLowerCase());
      });
    }

    _filterCacheKey = key;
    _filterCacheSourceLen = data.length;
    _filterCache = list;
    return list;
  }

  Widget _upgradeBanner(BuildContext context, int hiddenCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gratis: viser $_freeLimit butikker. $hiddenCount skjult. Oppgrader for å se alle + flere filtre.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {
              // TODO: naviger til premium-side om du har den
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium-skjerm kommer her 👌')),
              );
            },
            child: const Text('Oppgrader'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDebugAdmin() async {
    if (!kDebugMode) return;

    final isPrem = await _premiumSvc.getIsPremium();
    if (!mounted) return;
    final showBadges = await _premiumSvc.getShowBadges(fallback: true);
    if (!mounted) return;
    final freeLimit = await _premiumSvc.getFreeLimit(fallback: 30);
    if (!mounted) return;

    if (!mounted) return;

    bool tmpPrem = isPrem;
    bool tmpBadges = showBadges;
    double tmpLimit = freeLimit.toDouble();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Admin (debug)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Premium aktiv'),
                value: tmpPrem,
                onChanged: (v) => (ctx as Element).markNeedsBuild(),
              ),
              SwitchListTile(
                title: const Text('Vis badge'),
                value: tmpBadges,
                onChanged: (v) => (ctx as Element).markNeedsBuild(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Free limit:'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: tmpLimit,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: tmpLimit.round().toString(),
                      onChanged: (v) => (ctx as Element).markNeedsBuild(),
                    ),
                  ),
                ],
              ),
              Text('Viser: ${tmpLimit.round()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () async {
                await _premiumSvc.setIsPremium(tmpPrem);
                if (!mounted) return;
                await _premiumSvc.setShowBadges(tmpBadges);
                if (!mounted) return;
                await _premiumSvc.setFreeLimit(tmpLimit.round());
                if (!mounted) return;
                if (!mounted) return;
                setState(() {
                  _isPremium = tmpPrem;
                  _showBadges = tmpBadges;
                  _freeLimit = tmpLimit.round();
                  _filterCacheKey = ''; // bust cache
                });
                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Lagre'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _openDebugAdmin,
          child: const Text('EuroBonus Shopping'),
        ),
        actions: [
          IconButton(
            tooltip: 'Oppdater',
            onPressed: () {
              setState(() {
                _futureShops = _repo.fetchShops(forceRefresh: true);
                _filterCacheKey = '';
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Feil: ${snap.error}'),
              ),
            );
          }

          final data = snap.data ?? const <ShopOffer>[];
          final categories = _getCategoriesCached(data);

          // ensure current dropdown value exists
          if (!categories.contains(_category)) {
            _category = 'Alle';
          }

          final filtered = _applyFilters(data);

          final isGated = !_isPremium && filtered.length > _freeLimit;
          final visible =
              isGated ? filtered.take(_freeLimit).toList() : filtered;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Søk butikk',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      items: categories
                          .map((c) => DropdownMenuItem<String>(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _category = v ?? 'Alle';
                        _filterCacheKey = '';
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Kun kampanjer'),
                    selected: _onlyCampaigns,
                    onSelected: (v) => setState(() {
                      _onlyCampaigns = v;
                      _filterCacheKey = '';
                    }),
                  ),
                  FilterChip(
                    label: const Text('Favoritter først'),
                    selected: _favFirst,
                    onSelected: (v) => setState(() {
                      _favFirst = v;
                      _filterCacheKey = '';
                    }),
                  ),
                  FilterChip(
                    label: const Text('Sorter på rate'),
                    selected: _sortByRate,
                    onSelected: (v) => setState(() {
                      _sortByRate = v;
                      _filterCacheKey = '';
                    }),
                  ),
                ],
              ),
              if (isGated)
                _upgradeBanner(context, filtered.length - _freeLimit),
              const SizedBox(height: 6),
              Text(
                'Viser ${visible.length} av ${filtered.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ...visible.map((s) {
                final name = _nameOf(s).trim();
                final rate = _rateOf(s);
                final url = _urlOf(s).trim();
                final cat = _categoryOf(s).trim();
                final isCamp = _isCampaignOf(s);

                return Card(
                  child: ListTile(
                    leading: Icon(isCamp ? Icons.local_offer : Icons.store),
                    title: Text(name.isEmpty ? 'Ukjent butikk' : name),
                    subtitle:
                        Text('$cat • ${rate.toStringAsFixed(2)} poeng/kr'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showBadges)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.15),
                            ),
                            child: Text(isCamp ? 'Kampanje' : 'Standard'),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Åpne',
                          onPressed: url.isEmpty ? null : () => _openUrl(url),
                          icon: const Icon(Icons.open_in_new),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
