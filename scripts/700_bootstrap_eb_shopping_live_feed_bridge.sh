#!/usr/bin/env bash
set -euo pipefail

mkdir -p lib/features/offers
mkdir -p docs
mkdir -p scripts
mkdir -p .tmp_ai

cat > docs/AI_RULES.md <<'DOC'
# AI Rules

- Alle kodeendringer skal leveres som cat-scripts (bash) som oppretter eller oppdaterer filer under `scripts/`.
- Ikke lever lim-inn-kode som krever manuell redigering i `lib/`, `ios/`, `android/` eller andre prosjektmapper.
- Endringer skal være raske å bruke: ett script skal kunne limes inn og kjøres.
- Når eksisterende filer skal patches, skal patchen også leveres som script under `scripts/`.
- Vær presis. Ikke gjett i eksisterende filer hvis filinnhold ikke er kjent.
DOC

cat > lib/features/offers/eb_shopping_offer_vm.dart <<'DART'
class EbShoppingOfferVm {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? merchantName;
  final String? pointsText;
  final String? ctaText;
  final String? deeplink;
  final String category;
  final bool featured;
  final bool sponsored;
  final int priority;
  final DateTime? expiresAt;
  final Map<String, dynamic> raw;

  const EbShoppingOfferVm({
    required this.id,
    required this.title,
    required this.category,
    required this.raw,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.merchantName,
    this.pointsText,
    this.ctaText,
    this.deeplink,
    this.featured = false,
    this.sponsored = false,
    this.priority = 0,
    this.expiresAt,
  });

  bool get isExpired {
    final dt = expiresAt;
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }
}
DART

cat > lib/features/offers/eb_shopping_offers_adapter.dart <<'DART'
import 'eb_shopping_offer_vm.dart';

class EbShoppingOffersAdapter {
  const EbShoppingOffersAdapter();

  EbShoppingOfferVm? fromFeedItem(dynamic item) {
    if (item == null) return null;

    final map = _asMap(item);
    if (map == null) return null;

    final id = _str(map, ['id', 'offerId', 'uuid']);
    final title = _str(map, ['title', 'name', 'headline']);

    if (id == null || id.isEmpty) return null;
    if (title == null || title.isEmpty) return null;

    final expiresAtRaw = _first(map, ['expiresAt', 'expiryDate', 'validTo']);
    DateTime? expiresAt;
    if (expiresAtRaw is String && expiresAtRaw.trim().isNotEmpty) {
      expiresAt = DateTime.tryParse(expiresAtRaw);
    }

    final category = (_str(map, [
          'category',
          'vertical',
          'placement',
          'type'
        ]) ??
        'eb_shopping')
        .trim();

    return EbShoppingOfferVm(
      id: id,
      title: title,
      subtitle: _str(map, ['subtitle', 'subTitle', 'tagline']),
      description: _str(map, ['description', 'body', 'details']),
      imageUrl: _str(map, ['imageUrl', 'image', 'thumbnailUrl']),
      merchantName: _str(map, ['merchantName', 'merchant', 'brand']),
      pointsText: _str(map, ['pointsText', 'rewardText', 'bonusText']),
      ctaText: _str(map, ['ctaText', 'ctaLabel', 'buttonText']),
      deeplink: _str(map, ['deeplink', 'url', 'targetUrl', 'trackingUrl']),
      category: category,
      featured: _bool(map, ['featured', 'isFeatured']) ?? false,
      sponsored: _bool(map, ['sponsored', 'isSponsored', 'ad']) ?? false,
      priority: _int(map, ['priority', 'rank', 'score']) ?? 0,
      expiresAt: expiresAt,
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic>? _asMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    try {
      final dynamic json = item.toJson();
      if (json is Map<String, dynamic>) {
        return json;
      }
    } catch (_) {}
    return null;
  }

  dynamic _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return map[key];
    }
    return null;
  }

  String? _str(Map<String, dynamic> map, List<String> keys) {
    final value = _first(map, keys);
    if (value == null) return null;
    return value.toString().trim();
  }

  bool? _bool(Map<String, dynamic> map, List<String> keys) {
    final value = _first(map, keys);
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  int? _int(Map<String, dynamic> map, List<String> keys) {
    final value = _first(map, keys);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
DART

cat > lib/features/offers/eb_shopping_offers_datasource.dart <<'DART'
import 'eb_shopping_offer_vm.dart';
import 'eb_shopping_offers_adapter.dart';

class EbShoppingOffersDataSource {
  final dynamic offersFeedRepository;
  final EbShoppingOffersAdapter adapter;
  final Future<List<EbShoppingOfferVm>> Function()? legacyFallbackLoader;

  const EbShoppingOffersDataSource({
    required this.offersFeedRepository,
    this.adapter = const EbShoppingOffersAdapter(),
    this.legacyFallbackLoader,
  });

  Future<List<EbShoppingOfferVm>> load({
    bool allowFallback = true,
    int limit = 50,
  }) async {
    try {
      final response = await offersFeedRepository.fetchOffersFeed();
      final items = _extractItems(response);

      final mapped = items
          .map(adapter.fromFeedItem)
          .whereType<EbShoppingOfferVm>()
          .where(_isRelevantForEbShopping)
          .where((e) => !e.isExpired)
          .toList()
        ..sort((a, b) {
          final featuredCompare =
              (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
          if (featuredCompare != 0) return featuredCompare;
          return b.priority.compareTo(a.priority);
        });

      if (mapped.isNotEmpty) {
        return mapped.take(limit).toList();
      }
    } catch (_) {
      // Silent fallback by design in this migration phase.
    }

    if (allowFallback && legacyFallbackLoader != null) {
      return legacyFallbackLoader!.call();
    }

    return <EbShoppingOfferVm>[];
  }

  List<dynamic> _extractItems(dynamic response) {
    if (response == null) return <dynamic>[];

    try {
      final dynamic items = response.items;
      if (items is List) return items;
    } catch (_) {}

    try {
      final dynamic offers = response.offers;
      if (offers is List) return offers;
    } catch (_) {}

    try {
      final dynamic json = response.toJson();
      if (json is Map<String, dynamic>) {
        final items = json['items'];
        if (items is List) return items;

        final offers = json['offers'];
        if (offers is List) return offers;
      }
    } catch (_) {}

    return <dynamic>[];
  }

  bool _isRelevantForEbShopping(EbShoppingOfferVm offer) {
    final haystack = [
      offer.category,
      offer.title,
      offer.subtitle,
      offer.description,
      offer.merchantName,
      offer.pointsText,
      offer.raw['channel']?.toString(),
      offer.raw['surface']?.toString(),
      offer.raw['placement']?.toString(),
      offer.raw['program']?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains('eb shopping') ||
        haystack.contains('eurobonus shopping') ||
        haystack.contains('shopping portal') ||
        haystack.contains('online shopping') ||
        haystack.contains('sas shopping') ||
        offer.category.toLowerCase().contains('shopping');
  }
}
DART

cat > docs/EB_SHOPPING_LIVE_FEED_INTEGRATION_PLAN.md <<'DOC'
# EB Shopping live feed integration plan

## Mål
Koble kun `eb_shopping_page.dart` til backend offers feed, med fallback til legacy offers.

## Regler
- Ikke migrer hele appen nå
- Ikke skriv om hele widget-treet
- Bytt kun datasource først
- Legacy skal fortsatt fungere hvis live feed feiler eller er tom

## Filer opprettet
- `lib/features/offers/eb_shopping_offer_vm.dart`
- `lib/features/offers/eb_shopping_offers_adapter.dart`
- `lib/features/offers/eb_shopping_offers_datasource.dart`

## Trygg patch-strategi
1. Importer datasource + vm i `eb_shopping_page.dart`
2. Opprett lokal loader:
   - prøv live feed
   - fallback til legacy
3. Bruk eksisterende render-flow
4. Ikke endre design, bare datasource
5. Kjør analyze
6. Test live, tom feed, feil, deeplink

## Ting som ikke skal gjøres i samme patch
- ny layout
- ny filtermotor
- full app-migrering
- ny card-komponent
- aggressiv cleanup
DOC

cat > scripts/701_add_eb_shopping_live_feed_bridge.sh <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

echo "==> 701_add_eb_shopping_live_feed_bridge"
echo "Bridge-lag finnes allerede hvis 700 er kjørt."
echo "Kjører flutter analyze manuelt etterpå."
SCRIPT
chmod +x scripts/701_add_eb_shopping_live_feed_bridge.sh

cat > scripts/702_repo_inspect_eb_shopping_inputs.sh <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Repo inspection for EB shopping integration inputs"
mkdir -p .tmp_ai

{
  echo "### FILES"
  find lib -type f | sort
  echo

  echo "### MATCH: eb_shopping_page"
  grep -RIn "eb_shopping_page" lib || true
  echo

  echo "### MATCH: class OffersFeedRepository"
  grep -RIn "class OffersFeedRepository" lib || true
  echo

  echo "### MATCH: fetchOffersFeed"
  grep -RIn "fetchOffersFeed" lib || true
  echo

  echo "### MATCH: getOffersFeed"
  grep -RIn "getOffersFeed" lib || true
  echo

  echo "### MATCH: legacy offer loaders"
  grep -RInE "_load.*offer|load.*offer|offers.*load|legacy.*offer|Offer" lib/pages lib/features lib/widgets 2>/dev/null || true
  echo

  echo "### MATCH: deeplink / cta / url"
  grep -RInE "deeplink|cta|targetUrl|trackingUrl|launchUrl|url_launcher" lib 2>/dev/null || true
  echo

  echo "### MATCH: EB shopping widgets/cards"
  grep -RInE "OfferCard|offer card|shopping|eb shopping|EuroBonus" lib/pages lib/widgets 2>/dev/null || true
  echo
} > .tmp_ai/eb_shopping_integration_inputs.txt

echo "✅ Skrev .tmp_ai/eb_shopping_integration_inputs.txt"
sed -n '1,260p' .tmp_ai/eb_shopping_integration_inputs.txt
SCRIPT
chmod +x scripts/702_repo_inspect_eb_shopping_inputs.sh

echo "✅ Opprettet:"
echo "  - docs/AI_RULES.md"
echo "  - docs/EB_SHOPPING_LIVE_FEED_INTEGRATION_PLAN.md"
echo "  - lib/features/offers/eb_shopping_offer_vm.dart"
echo "  - lib/features/offers/eb_shopping_offers_adapter.dart"
echo "  - lib/features/offers/eb_shopping_offers_datasource.dart"
echo "  - scripts/701_add_eb_shopping_live_feed_bridge.sh"
echo "  - scripts/702_repo_inspect_eb_shopping_inputs.sh"
echo
echo "Kjør så:"
echo "  bash scripts/702_repo_inspect_eb_shopping_inputs.sh"
echo "  flutter analyze"
