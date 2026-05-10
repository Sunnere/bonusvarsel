import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bonusvarsel/widgets/bonusvarsel_feed_list.dart';
import 'package:bonusvarsel/widgets/bonusvarsel_prefs_bar.dart';
import 'package:bonusvarsel/pages/bonusvarsel_paywall_page.dart';
import 'package:bonusvarsel/services/api_service.dart';
import 'package:flutter/material.dart';
import '../features/offers/eb_shopping_offers_datasource.dart';
import '../features/offers/eb_shopping_offer_vm.dart';
import '../theme/app_theme.dart';
import '../services/ad_metrics_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonusvarsel/models/subscription_tier.dart';
import '../services/entitlement_service.dart';
import 'package:bonusvarsel/widgets/ad_slot.dart';
import 'package:bonusvarsel/widgets/elite_header_widget.dart';
import 'package:bonusvarsel/widgets/elite_badge_chip.dart';
import 'package:bonusvarsel/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bonusvarsel/models/shop_offer.dart';
import 'package:bonusvarsel/services/eb_repository.dart';
import 'package:bonusvarsel/services/premium_service.dart';
import '../models/ad_slot.dart';

import 'ad_debug_page.dart';

// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings, unused_element
import 'package:bonusvarsel/pages/premium_page.dart';
import '../paywall/paywall_launcher_button.dart';
import '../paywall/paywall_preview_page.dart';
import 'package:bonusvarsel/widgets/best_recommendation_card.dart';

import '../services/offers_feed_repository.dart';
class EbShoppingPage extends StatefulWidget {
  const EbShoppingPage({super.key});

  @override
  State<EbShoppingPage> createState() => _EbShoppingPageState();
}

const double boostThreshold = 8.0;

class _EbShoppingPageState extends State<EbShoppingPage> {
  late final EbShoppingOffersDataSource _offersDataSource;

    // ignore: unused_element_parameter
    void onOpenPremiumPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallPreviewPage(),
      ),
    );
  
  }

  String _apiUserTier = 'free';

  int _apiFeedRefreshToken = 0;

  // BV_SAFE_TIER_HELPER
  SubscriptionTier _safeTier() {
    try {
      final dyn = PremiumService.instance as dynamic;
      final t = dyn.currentTier ??
          dyn.tier ??
          dyn.subscriptionTier ??
          dyn.currentSubscriptionTier;
      if (t is SubscriptionTier) return t;
    } catch (_) {
      // ignore: avoid_catches_without_on_clauses
    }
    return SubscriptionTier.free;
  }

  bool get _isElite {
    // TODO: Koble til faktisk subscription-logikk senere
    return true; // midlertidig for stabil visning
  }

  // --- ELITE_V2_TOP_CARDS ---
  Widget _eliteTopCardsSection() {
    return FutureBuilder<List<AdSlot>>(
      future: AdService.instance.pickAds(
        placement: 'elite_top',
        count: 3,
        requireAnyTags: const <String>['cards', 'elite'],
      ),
      builder: (context, snap) {
        final ads = snap.data ?? const <AdSlot>[];
        if (ads.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            
children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live API-feed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Denne seksjonen henter ekte tilbud fra /v1/feed.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 260,
                            child: BonusvarselFeedList(refreshToken: _apiFeedRefreshToken),
                          ),
                          SizedBox(height: 12),
                          BonusvarselPrefsBar(
                            onChanged: () {
                              if (!mounted) return;
                              setState(() {
                                _apiFeedRefreshToken++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildApiUpgradeHint(context),
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        ],
                      ),
                    ),

              // --- ELITE_V2_TOP_CARDS_INJECT ---
              if (_isElite) _eliteTopCardsSection(),

              Text(
                'Beste kort akkurat nå',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              EliteHeaderWidget(
                  title: 'Beste kort akkurat nå',
                  trailing: const EliteBadgeChip(
                    type: EliteBadgeType.elite,
                  )),
              Column(
                children: ads
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AdSlotCard(slot: a, placement: 'elite_top'),
                        ))
                    .toList(),
              ),
              const Divider(height: 24),
            ],
          ),
        );
      },
    );
  }

  final EbRepository _repo = EbRepository();
  final PremiumService _premiumSvc = const PremiumService();

  late Future<List<ShopOffer>> _futureShops;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  // Filters / prefs
  String _category = 'Alle';
  // ignore: prefer_final_fields
  String _source = 'Alle'; // Alle / SAS / Trumf

  bool _onlyCampaigns = false;
  List<String> _favoritesCache = [];

  Widget _filterChip(String label, bool selected, Color color, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        )),
      selected: selected,
      selectedColor: color,
      backgroundColor: const Color(0xFF1E293B),
      checkmarkColor: Colors.black,
      side: BorderSide(color: selected ? color : Colors.white24),
      onSelected: (v) => onSelected(v),
    );
  }
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
    _offersDataSource = EbShoppingOffersDataSource(
      offersFeedRepository: OffersFeedRepository(),
    );
_futureShops = _repo.fetchShops(forceRefresh: false);

    _loadPremiumPrefs();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadPremiumPrefs() async {
    // Bruk EntitlementService som kilde til sannhet
    await EntitlementService.instance.load();
    final isPrem = EntitlementService.instance.isPremium;
    if (!mounted) return;
    final showBadges = await _premiumSvc.getShowBadges(fallback: true);
    if (!mounted) return;
    final freeLimit = isPrem ? 9999 : await _premiumSvc.getFreeLimit(fallback: 30);
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
      setState(() {});
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
  }

  // ---- Robust helpers ----
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

  String _sourceOf(dynamic it) {
    // Robust: støtter både Map og typed objects uten å knekke build.
    try {
      final v = (it as dynamic).source;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (it as dynamic).program;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    if (it is Map) {
      final v = it['source'] ?? it['program'] ?? it['provider'];
      if (v is String && v.isNotEmpty) return v;
    }
    return 'SAS';
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

  List<ShopOffer> _applyFilters(List<ShopOffer> data) {
    final q = _searchCtrl.text.trim().toLowerCase();

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

    if (_source != 'Alle') {
      list = list.where((it) => _sourceOf(it) == _source).toList();
    }

    if (_onlyCampaigns) {
      list = list.where((it) => _isCampaignOf(it)).toList();
    }

    // Favoritter-filter: vis favoritter øverst eller kun favoritter
    if (_favFirst) {
      // Hent favoritter fra prefs-cache (bruker tom liste som fallback)
      final favs = _favoritesCache;
      if (favs.isNotEmpty) {
        final favList = list.where((it) => favs.contains(_nameOf(it))).toList();
        final restList = list.where((it) => !favs.contains(_nameOf(it))).toList();
        list = [...favList, ...restList];
      }
    }

    // Høy rate: sorter alltid på rate når valgt
    if (_sortByRate) {
      list.sort((a, b) {
        final r = _rateOf(b).compareTo(_rateOf(a));
        if (r != 0) return r;
        return _nameOf(a).toLowerCase().compareTo(_nameOf(b).toLowerCase());
      });
    }

    // Ved høy rate eller favoritter: vis alle (ikke kutt på freeLimit)
    if (_sortByRate || _favFirst) {
      _filterCacheKey = key;
      _filterCacheSourceLen = data.length;
      _filterCache = list;
      return list;
    }

    _filterCacheKey = key;
    _filterCacheSourceLen = data.length;
    _filterCache = list;
    return list;
  }

  Future<void> _refreshApiUserTier() async {
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _apiUserTier = (me['tier'] ?? 'free').toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiUserTier = 'free';
      });
    }
  }

  Widget _buildApiUpgradeHint(BuildContext context) {
    if (_apiUserTier == 'elite') {
      return const SizedBox.shrink();
    }

    final bool isPremium = _apiUserTier == 'premium';
    final String title = isPremium
        ? 'Vil du se alt? Gå til Elite'
        : 'Lås opp mer med Premium';
    final String body = isPremium
        ? 'Elite gir deg tilgang til elite-tilbud, maksimal synlighet og tidlig tilgang.'
        : 'Premium gir deg bedre innsyn i boosts, premium-rates og skjulte poengmuligheter.';
    final String buttonLabel = isPremium ? 'Se Elite' : 'Se Premium';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0x142F80ED),
            child: Icon(Icons.workspace_premium, size: 18, color: Color(0xFF2F80ED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () async {
                    final upgraded = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const BonusvarselPaywallPage(),
                      ),
                    );
                    if (upgraded == true && mounted) {
                      await _refreshApiUserTier();
                      setState(() {
                        _apiFeedRefreshToken++;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Oppgradering registrert. Seksjonen er oppdatert.'),
                        ),
                      );
                    }
                  },
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceFilter(BuildContext context) {
// ignore: unused_local_variable
// ignore: unused_local_variable
final cs = Theme.of(context).colorScheme;
Widget chip(String label, String value) {
      final selected = _source == value;
      final bg = selected
          ? cs.primary.withValues(alpha: 0.22)
          : cs.onSurface.withValues(alpha: 0.08);

      final border = selected
          ? cs.primary.withValues(alpha: 0.55)
          : cs.onSurface.withValues(alpha: 0.14);

      final fg = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.86);

      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          if (_source == value) return;
          setState(() => _source = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                const SizedBox(height: 16),
                // Flyttet annonse: vises nær nivåvalg i stedet for midt i butikklisten
                const SizedBox(height: 16),

        Text(
          'Kilde',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('Alle', 'Alle'),
            chip('SAS', 'SAS'),
            chip('Trumf', 'Trumf'),
          ],
        ),
      ],
    );
  }

  
      Widget _upgradeBanner(BuildContext context, int hiddenCount) {
  // Kilde-aware copy (Alle / SAS / Trumf)
  final cs = Theme.of(context).colorScheme;
  final String? scope = (_source == 'Alle') ? null : _source;

  final String lockedLine = hiddenCount > 0
      ? (scope == null
          ? 'Du går glipp av ekstra poeng i $hiddenCount butikker'
          : 'Du går glipp av ekstra poeng i $hiddenCount $scope-butikker')
      : (scope == null
          ? 'Du går glipp av ekstra poeng'
          : 'Du går glipp av ekstra poeng hos $scope');

  final String ctaLabel =
      (scope == null) ? '🔓 Få alle poengene' : '🔓 Lås opp $scope-poeng';

  return const SizedBox.shrink();
}

  Future<void> _openDebugAdmin() async {
    // kDebugMode-sjekk fjernet midlertidig for testing

    final isPrem = await _premiumSvc.getIsPremium();
    if (!mounted) return;
    final showBadges = await _premiumSvc.getShowBadges(fallback: true);
    if (!mounted) return;
    final freeLimit = await _premiumSvc.getFreeLimit(fallback: 30);
    if (!mounted) return;

    bool tmpPrem = isPrem;
    bool tmpBadges = showBadges;
    double tmpLimit = freeLimit.toDouble();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Admin (debug)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Premium aktiv'),
                value: tmpPrem,
                onChanged: (v) {
                  tmpPrem = v;
                  (context as Element).markNeedsBuild();
                },
              ),
              SwitchListTile(
                title: Text('Vis badge'),
                value: tmpBadges,
                onChanged: (v) {
                  tmpBadges = v;
                  (context as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Free limit:'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: tmpLimit,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      onChanged: (v) {
                        tmpLimit = v;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                ],
              ),
              Text('Viser: ${tmpLimit.round()}'),
            ],
          ),
          actions: [
              PaywallLauncherButton(
                tooltip: 'Test Premium paywall',
              ),
              
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () async {
                await _premiumSvc.setIsPremium(tmpPrem);
                await _premiumSvc.setShowBadges(tmpBadges);
                await _premiumSvc.setFreeLimit(tmpLimit.round());

                if (!mounted) return;
                setState(() {
                  _isPremium = tmpPrem;
                  _showBadges = tmpBadges;
                  _freeLimit = tmpLimit.round();
                  _filterCacheKey = '';
                });

                if (mounted) Navigator.of(context).pop();
              },
              child: Text('Lagre'),
            ),
          ],
        );
      },
    );
  }

  // --- ELITE_V2_SECTION ---
  Widget _eliteV2TopCards(SubscriptionTier tier) {
    if (tier != SubscriptionTier.elite) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beste kort akkurat nå',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          FutureBuilder<List<AdSlot>>(
            future: AdService.instance.pickAds(placement: 'elite_top'),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 8);
              }
              final list = (snap.data ?? const <AdSlot>[]);
              if (list.isEmpty) return const SizedBox.shrink();

              final top3 = list.take(3).toList();
              return Column(
                children: [
// ignore: unused_local_variable
                  for (final slot in top3) ...[

                    const SizedBox(height: 4),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }



  String _logoAssetForShopTitle(String title) {
    final key = title.toLowerCase().trim();

    if (key.contains('sas')) return 'assets/brands/sas_eurobonus.png';
    if (key.contains('trumf')) return 'assets/brands/trumf.png';
    if (key.contains('visa')) return 'assets/brands/visa.png';
    if (key.contains('mastercard')) return 'assets/brands/mastercard.png';
    if (key.contains('amex')) return 'assets/brands/amex.png';
    if (key.contains('lunar')) return 'assets/brands/lunar.png';

    if (key.contains('allente')) return 'assets/brands/allente.png';
    if (key.contains('telia')) return 'assets/brands/telia.png';
    if (key == 'ice' || key.contains(' ice ')) return 'assets/brands/ice.png';
    if (key.contains('ishavskraft')) return 'assets/brands/ishavskraft.png';
    if (key.contains('bærum energi') || key.contains('baerum energi')) return 'assets/brands/baerum_energi.png';

    if (key.contains('zalando')) return 'assets/brands/zalando.png';
    if (key.contains('nike')) return 'assets/brands/nike.png';
    if (key.contains('adidas')) return 'assets/brands/adidas.png';
    if (key.contains('komplett')) return 'assets/brands/komplett.png';
    if (key.contains('power')) return 'assets/brands/power.png';
    if (key.contains('elkjøp') || key.contains('elkjop')) return 'assets/brands/elkjop.png';
    if (key.contains('apotek 1') || key.contains('apotek1')) return 'assets/brands/apotek1.png';
    if (key.contains('vita')) return 'assets/brands/vita.png';
    if (key.contains('blivakker')) return 'assets/brands/blivakker.png';
    if (key.contains('boozt')) return 'assets/brands/boozt.png';
    if (key.contains('ellos')) return 'assets/brands/ellos.png';
    if (key.contains('cdon')) return 'assets/brands/cdon.png';

    return '';
  }

  Widget _shopLeadingLogo(String title) {
    final asset = _logoAssetForShopTitle(title);

    if (asset.isEmpty) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F1F7),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          title.trim().isNotEmpty ? title.trim().characters.first.toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF1E4B59),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        asset,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1F7),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              title.trim().isNotEmpty ? title.trim().characters.first.toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF1E4B59),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _openDebugAdmin,
          child: Text('EuroBonus Shopping', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
        
        if (kDebugMode)
          IconButton(
            tooltip: 'Ad debug',
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdDebugPage()),
              );
            },
          ),
],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<ShopOffer>>(
        future: _futureShops,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text('Feil: ${snap.error}'),
              ),
            );
          }

          final data = snap.data ?? const <ShopOffer>[];
          final categories = _getCategoriesCached(data);

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

              const _PremiumHeader(),
              SmartBestRecommendationCard(
                futureOffers: _futureShops,
                amountNok: 5000,
                onTapPaywall: () => _openPremiumPage(context),
              ),
              // BV_SOURCE_FILTER
              const SizedBox(height: 4),
              const SizedBox(height: 8),
              _buildSourceFilter(context),
              if (_source == 'Alle')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Toppbutikker akkurat nå',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),

              // BV_ELITE_V2_INJECT
              if (_safeTier() == SubscriptionTier.elite)
                _eliteV2TopCardsSection(context),

              
              // --- Filters: search + category (equal width, 44px) ---
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          labelText: 'Søk butikk',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  // KATEGORI-DROPDOWN MIDLERTIDIG SKJULT - aktiveres når API returnerer kategori-data
                  // const SizedBox(width: 10),
                  // Expanded(child: SizedBox(height: 44, child: DropdownButtonFormField(...))),
                ],
              ),
              const SizedBox(height: 4),

              // --- Filters: chips ---
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _filterChip('🎯 Kampanjer', _onlyCampaigns, const Color(0xFFFF6B35),
                    (v) => setState(() { _onlyCampaigns = v; _filterCacheKey = ''; })),
                  _filterChip('⭐ Favoritter', _favFirst, const Color(0xFFFFD700),
                    (v) => setState(() { _favFirst = v; _filterCacheKey = ''; })),
                  _filterChip('🔥 Høy rate', _sortByRate, const Color(0xFF22C55E),
                    (v) => setState(() { _sortByRate = v; _filterCacheKey = ''; })),
                ],
              ),

              if (isGated)
                _upgradeBanner(context, (_isPremium ? 0 : (filtered.length - _freeLimit).clamp(0, 1 << 30).toInt())),
              const SizedBox(height: 4),
              Text(
                'Viser ${visible.length} av ${filtered.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              ...visible.map((s) {
                final name = _nameOf(s).trim();
                final rate = _rateOf(s);
                final url = _urlOf(s).trim();
                final cat = _categoryOf(s).trim();
                final isCamp = _isCampaignOf(s);

                return Card(
                  child: ListTile(
                    onTap: url.isEmpty ? null : () => _openUrl(url),
                    leading: Icon(isCamp ? Icons.local_offer : Icons.store),
                    title: Text(name),
                    
subtitle: Builder(
  builder: (context) {
    final isBoost = rate >= boostThreshold;
    final isLocked = isBoost && !_isPremium;

    if (isLocked) {
      return const Text(
        '🔒 🔒 Boost i Premium',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }

    return Text('$cat • ${rate.toStringAsFixed(2)} poeng/kr');
  },
),

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
                            child: Text(isCamp ? 'Kampanje' : 'Basis'),
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
          ),
        ],
      ),
    );
  }

  // BV_ELITE_V2_SECTION
  Widget _eliteV2TopCardsSection(BuildContext context) {
    return FutureBuilder<List<AdSlot>>(
      future: AdService.instance.pickAds(
        placement: 'elite_top_cards',
        count: 3,
        requireAnyTags: const ['cards'],
      ),
      builder: (context, snap) {
        final ads = (snap.data ?? const <AdSlot>[]);
        if (ads.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beste kort akkurat nå',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ...ads.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdSlotCard(
                      slot: a,
                      placement: 'elite_top_cards',
                    ),
                  )),
              const Divider(),
            ],
          ),
        );
      },
    );
  }
}

class _UpgradeCtaButtonState extends State<_UpgradeCtaButton>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late final AnimationController _pulseCtl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    // 1x pulse (ikke loop)
    _pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
    ]).animate(_pulseCtl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pulseCtl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _pulseCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFD4AF37);

    final glow = BoxShadow(
      color: gold.withValues(alpha: _hover ? 0.45 : 0.25),
      blurRadius: _hover ? 18 : 14,
      spreadRadius: _hover ? 1.5 : 1.0,
      offset: const Offset(0, 8),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        scale: _hover ? 1.035 : 1.0,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) =>
              Transform.scale(scale: _pulse.value, child: child),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [glow],
            ),
            child: FilledButton(
              onPressed: widget.onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeCtaButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;

  const _UpgradeCtaButton({
    required this.onPressed,
    required this.label,
  });
@override
  State<_UpgradeCtaButton> createState() => _UpgradeCtaButtonState();
}

class _PremiumHeader extends StatelessWidget {
  final VoidCallback? onOpenPremiumPaywall;

  const _PremiumHeader({
    this.onOpenPremiumPaywall,
  });

  @override
  Widget build(BuildContext context) {
    // Header: ren blå (ikke navy), funker både i light/dark mode.
    const headerA = Color(0xFF2F80ED); // ren blå (lysere)
    const headerB = Color(0xFF0B4AA2); // dypere blå for dybde

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, minHeight: 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [headerA, headerB],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tjen flere poeng på shopping',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 0.1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Velg nivå og se hva som gir mest verdi for deg',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),

                // Riktig rekkefølge: Trygt, Premium, Elite
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: onOpenPremiumPaywall,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Gratis'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                      label: const Text('Premium'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _openPremiumPage(context),
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text('Elite'),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderPill({required this.icon, required this.text});

  // Premium: luksus blå. Elite: blå/lilla + gull-touch. Trygt: dyrere grønn.
  Color _accent() {
    switch (text) {
      case 'Premium':
        return const Color(0xFF2F80ED); // luksus blå
      case 'Elite':
        return const Color(0xFFD4AF37); // blå/lilla
      case 'Trygt':
          return const Color(0xFF2E7D32); // premium grønn // “dyrere” grønn (ikke neon)
      default:
        return Colors.white;
    }
  }

  Color _iconColor() {
    // Elite får gull-touch på ikon (trophy/medal) for statusfølelse.
    if (text == 'Elite') return const Color(0xFFD4AF37);
    return _accent();
  }

  Color _bg() {
    final a = _accent();
    // Litt mer “premium”-tint enn ren hvit-alpha.
    return a.withValues(alpha: 0.16);
  }

  Color _border() {
    final a = _accent();
    return a.withValues(alpha: 0.38);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border()),
        boxShadow: [
          BoxShadow(
            color: _accent().withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _iconColor()),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.96),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatsRow extends StatefulWidget {
  final String placement;
  const _HeaderStatsRow({required this.placement});

  @override
  State<_HeaderStatsRow> createState() => _HeaderStatsRowState();
}

class _HeaderStatsRowState extends State<_HeaderStatsRow> {
  Timer? _t;

  String _dayStamp(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<_HeaderStats> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ads = AdService.instance.getCreative();
    final metrics = AdMetricsService();

    final clicksAll = await metrics.clicksSnapshot();
    final impsAll = await metrics.impressionsSnapshot();

    int allClicks = 0;
    int allImps = 0;
    for (final ad in ads) {
      allClicks += clicksAll[ad.id] ?? 0;
      allImps += impsAll[ad.id] ?? 0;
    }
    final allCtr = (allImps <= 0) ? 0.0 : (allClicks / allImps);

    final day = _dayStamp(DateTime.now());

    int todayImps = 0;
    int todayClicks = 0;
    for (final ad in ads) {
      final impKey = 'ad_imp_day::$day::${widget.placement}::${ad.id}';
      final clkKey = 'ad_clk_day::$day::${widget.placement}::${ad.id}';
      todayImps += prefs.getInt(impKey) ?? 0;
      todayClicks += prefs.getInt(clkKey) ?? 0;
    }
    final todayCtr = (todayImps <= 0) ? 0.0 : (todayClicks / todayImps);

    return _HeaderStats(
      todayImps: todayImps,
      todayClicks: todayClicks,
      todayCtr: todayCtr,
      allImps: allImps,
      allClicks: allClicks,
      allCtr: allCtr,
    );
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _t = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<_HeaderStats>(
      future: _load(),
      builder: (context, snap) {
        final s = snap.data;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: 'I dag',
              value: s == null ? '…' : '${s.todayImps} visn / ${s.todayClicks} klikk',
              tone: cs.onPrimary.withValues(alpha: 0.12),
              border: cs.onPrimary.withValues(alpha: 0.18),
              fg: cs.onPrimary,
            ),
            _StatPill(
              label: 'CTR i dag',
              value: s == null ? '…' : '${(s.todayCtr * 100).toStringAsFixed(1)}%',
              tone: cs.onPrimary.withValues(alpha: 0.12),
              border: cs.onPrimary.withValues(alpha: 0.18),
              fg: cs.onPrimary,
            ),
            _StatPill(
              label: 'All time',
              value: s == null ? '…' : '${s.allImps} visn / ${s.allClicks} klikk',
              tone: cs.onPrimary.withValues(alpha: 0.12),
              border: cs.onPrimary.withValues(alpha: 0.18),
              fg: cs.onPrimary,
            ),
            _StatPill(
              label: 'CTR all time',
              value: s == null ? '…' : '${(s.allCtr * 100).toStringAsFixed(1)}%',
              tone: cs.onPrimary.withValues(alpha: 0.12),
              border: cs.onPrimary.withValues(alpha: 0.18),
              fg: cs.onPrimary,
            ),
          ],
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  final Color border;
  final Color fg;

  const _StatPill({
    required this.label,
    required this.value,
    required this.tone,
    required this.border,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStats {
  final int todayImps;
  final int todayClicks;
  final double todayCtr;

  final int allImps;
  final int allClicks;
  final double allCtr;

  _HeaderStats({
    required this.todayImps,
    required this.todayClicks,
    required this.todayCtr,
    required this.allImps,
    required this.allClicks,
    required this.allCtr,
  });
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String free;
  final String premium;

  const _ComparisonRow(this.label, this.free, this.premium);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          SizedBox(
            width: 54,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

void _openPremiumPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumPage()),
  );
}

void _showFreeVsPremium(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  const premiumShops = 230;
  const freeShops = 30;

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: cs.surface.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        title: Text(
          'Sammenlign nivåer',
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // Tabell: faste kolonner => stabil layout
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.6), // label
                  1: FixedColumnWidth(68), // Gratis
                  2: FixedColumnWidth(68), // Premium
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Gratis',
                          textAlign: TextAlign.right,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface.withValues(alpha: 0.75),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Premium',
                          textAlign: TextAlign.right,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface.withValues(alpha: 0.75),
                              ),
                        ),
                      ),
                    ],
                  ),

                  _cmpRow(ctx, cs, 'Antall butikker', '$freeShops', '$premiumShops'),
                  _cmpBoolRow(ctx, cs, 'Høy poengrate', false, true),
                  _cmpBoolRow(ctx, cs, 'Boost-tilbud', false, true),
                  _cmpRow(ctx, cs, 'Skjulte butikker', '200', '0'),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                'Start alltid handelen fra appen og fullfør kjøpet i samme økt. '
                'Hvis du bytter fane/app, åpner lenken på nytt, eller bruker kupong '
                'som ikke er tillatt, kan poengene utebli.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
              ),

              const SizedBox(height: 4),

              Text(
                'Du mister ekstra poeng hver gang du handler uten Premium.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                // Naviger til Premium/Elite-siden hvis du har en rute.
                // Hvis ikke: behold kun pop().
              },
              child: Text('Se Premium / Elite'),
            ),
          ),
        ],
      );
    },
  );
}

TableRow _cmpRow(BuildContext ctx, ColorScheme cs, String label, String freeVal, String premiumVal) {
  final t = Theme.of(ctx).textTheme.bodySmall;
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          label,
          style: t?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          freeVal,
          textAlign: TextAlign.right,
          style: t?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          premiumVal,
          textAlign: TextAlign.right,
          style: t?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    ],
  );
}

TableRow _cmpBoolRow(BuildContext ctx, ColorScheme cs, String label, bool freeOk, bool premiumOk) {
  final t = Theme.of(ctx).textTheme.bodySmall;
  Widget icon(bool ok) => Align(
        alignment: Alignment.centerRight,
        child: Icon(
          ok ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: ok ? const Color(0xFF4CAF50) : Colors.redAccent.withValues(alpha: 0.95),
        ),
      );

  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          label,
          style: t?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: icon(freeOk),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: icon(premiumOk),
      ),
    ],
  );

}

