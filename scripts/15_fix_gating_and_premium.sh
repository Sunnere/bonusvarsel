#!/usr/bin/env bash
set -euo pipefail

# Backup
TS="$(date +%s)"
for f in lib/pages/eb_shopping_page.dart lib/services/premium_service.dart lib/widgets/premium_badge.dart lib/pages/premium_page.dart; do
  if [ -f "$f" ]; then cp "$f" "$f.bak.$TS"; fi
done

############################################
# 1) PremiumService: legg til isPremium + restore
############################################
cat > lib/services/premium_service.dart <<'DART'
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const _kIsPremium = 'premium_is_premium';

  const PremiumService();

  Future<bool> getIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPremium) ?? false;
  }

  // Alias (noen filer kaller isPremium())
  Future<bool> isPremium() => getIsPremium();

  Future<void> setIsPremium(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, v);
  }

  // Placeholder restore (inntil du har ekte kjøp)
  Future<void> restore() async {
    // No-op for now. Når du kobler på IAP/RevenueCat etc:
    // hent purchases -> setIsPremium(true/false)
  }
}
DART

############################################
# 2) Premium badge: bruk getIsPremium() (og funker om isPremium() også brukes)
############################################
cat > lib/widgets/premium_badge.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class PremiumBadge extends StatelessWidget {
  final PremiumService premium;
  const PremiumBadge({super.key, this.premium = const PremiumService()});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: premium.getIsPremium(),
      builder: (context, snap) {
        final isPremium = snap.data ?? false;
        if (!isPremium) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'PRO',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
DART

############################################
# 3) EB Shopping: reparer parsing + gating (FREE_LIMIT=30) + banner
#    Bruker eksisterende repo/model slik du hadde (fetchShops/forceRefresh)
############################################
cat > lib/pages/eb_shopping_page.dart <<'DART'
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
  static const int FREE_LIMIT = 30;
  static const String _favKey = 'eb_shopping_favs';

  final _repo = EbRepository();
  final _premiumSvc = const PremiumService();

  late Future<List<ShopOffer>> _futureShops;

  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'Alle';
  bool _onlyCampaigns = false;
  bool _favFirst = false;
  bool _isPremium = false;

  final Set<String> _fav = <String>{};

  @override
  void initState() {
    super.initState();
    _futureShops = _repo.fetchShops();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favKey) ?? <String>[];
    final isPremium = await _premiumSvc.getIsPremium();

    if (!mounted) return;
    setState(() {
      _fav
        ..clear()
        ..addAll(favs);
      _isPremium = isPremium;
    });
  }

  Future<void> _saveFavs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favKey, _fav.toList()..sort());
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  List<ShopOffer> _applyFilters(List<ShopOffer> data) {
    final q = _searchCtrl.text.trim().toLowerCase();
    Iterable<ShopOffer> it = data;

    if (_category != 'Alle') {
      it = it.where((s) => (s.category).trim() == _category);
    }
    if (_onlyCampaigns) {
      it = it.where((s) => s.isCampaign == true);
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
        final r = b.rate.compareTo(a.rate);
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } else {
      list.sort((a, b) {
        final r = b.rate.compareTo(a.rate);
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    return list;
  }

  Widget _upgradeBanner(BuildContext context, int total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Du ser $FREE_LIMIT av $total butikker. Oppgrader til PRO for full liste + flere filtre.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              // Foreløpig: “fake” oppgradering via prefs
              // Bytt til ekte kjøp senere.
              _premiumSvc.setIsPremium(true).then((_) => _loadPrefs());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PRO aktivert (midlertidig) ✅')),
              );
            },
            child: const Text('Oppgrader'),
          ),
        ],
      ),
    );
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
          final data = snap.data ?? <ShopOffer>[];
          final filtered = _applyFilters(data);

          final cats = <String>{};
          for (final s in data) {
            final c = s.category.trim();
            if (c.isNotEmpty) cats.add(c);
          }
          final categories = <String>['Alle', ...cats.toList()..sort()];

          final visible = _isPremium ? filtered : filtered.take(FREE_LIMIT).toList();
          final isGated = !_isPremium && filtered.length > FREE_LIMIT;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Søk butikk…',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              // Kategori + chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Kategori',
                        ),
                        items: categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _category = v ?? 'Alle');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      selected: _onlyCampaigns,
                      label: const Text('Kampanjer'),
                      selectedColor: primary.withValues(alpha: 0.20),
                      onSelected: (v) => setState(() => _onlyCampaigns = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _favFirst,
                      label: const Text('Favoritter først'),
                      selectedColor: primary.withValues(alpha: 0.20),
                      onSelected: (v) => setState(() => _favFirst = v),
                    ),
                  ],
                ),
              ),

              // Banner (kun om gated)
              if (isGated) _upgradeBanner(context, filtered.length),

              // Count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${visible.length} butikker',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final shop = visible[i];
                    final isFav = _fav.contains(shop.name);

                    return ListTile(
                      leading: shop.isCampaign
                          ? const Icon(Icons.local_offer)
                          : const Icon(Icons.store),
                      title: Text(shop.name),
                      subtitle: Text(
                        '${shop.rate.toStringAsFixed(shop.rate % 1 == 0 ? 0 : 1)} poeng / 100 kr'
                        '${shop.category.trim().isEmpty ? '' : ' • ${shop.category}'}',
                      ),
                      trailing: IconButton(
                        tooltip: isFav ? 'Fjern favoritt' : 'Legg til favoritt',
                        icon: Icon(isFav ? Icons.star : Icons.star_border),
                        onPressed: () {
                          setState(() {
                            if (isFav) {
                              _fav.remove(shop.name);
                            } else {
                              _fav.add(shop.name);
                            }
                          });
                          _saveFavs();
                        },
                      ),
                      onTap: () => _openUrl(shop.url),
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

############################################
# 4) Premium page: fjern restore-feil ved å bruke premiumSvc.restore()
#    (minimal patch – du kan bygge mer UI senere)
############################################
if [ -f lib/pages/premium_page.dart ]; then
cat > lib/pages/premium_page.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:bonusvarsel/services/premium_service.dart';

class PremiumPage extends StatelessWidget {
  PremiumPage({super.key});

  final _premium = const PremiumService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Her kommer betaling/fordeler. (Placeholder)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: cs.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('PRO gir deg flere filtre, varsler og bedre oversikt.'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _premium.setIsPremium(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PRO aktivert ✅')),
                    );
                  }
                },
                child: const Text('Aktiver PRO (midlertidig)'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await _premium.restore();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restore kjørt (placeholder)')),
                    );
                  }
                },
                child: const Text('Gjenopprett kjøp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART
fi

dart format lib/pages/eb_shopping_page.dart lib/services/premium_service.dart lib/widgets/premium_badge.dart lib/pages/premium_page.dart || true
flutter analyze
