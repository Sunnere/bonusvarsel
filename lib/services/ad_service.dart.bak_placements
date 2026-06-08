import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ad_slot.dart';

import 'ad_metrics_service.dart';

class _AdStats {
  final int impressions;
  final int clicks;
  const _AdStats(this.impressions, this.clicks);
}

class AdService {
  final AdMetricsService _metrics = AdMetricsService();

  // ================= SMART AD ENGINE =================

  static const double _ctrWeight = 1.0;
  static const double _recencyWeight = 0.3;
  static const double _partnerWeight = 0.5;
  static const double _affinityWeight = 0.8;
  static const double _fatiguePenalty = 1.5;

  
  // Guarantee / pacing
  static const double _guaranteeWeight = 1.0; // soft boost when under-delivered
  static const bool _hardGuarantee = false;   // set true to force delivery first
final Map<String, double> _userAffinity = {};

  double _partnerBoost(List<String> tags) {
    if (tags.contains('amex')) return 1.2;
    if (tags.contains('visa')) return 1.0;
    if (tags.contains('mastercard')) return 1.0;
    return 1.0;
  }

  double _affinityScore(List<String> tags) {
    double score = 0;
    for (final t in tags) {
      score += _userAffinity[t] ?? 0;
    }
    return score;
  }

  void recordUserAffinity(List<String> tags) {
    for (final t in tags) {
      _userAffinity[t] = (_userAffinity[t] ?? 0) + 0.1;
    }
  }

  double _smartScore({
    required double ctr,
    required List<String> tags,
    required int sessionExposure,
  }) {
    final partner = _partnerBoost(tags);
    final affinity = _affinityScore(tags);
    final fatigue = sessionExposure * _fatiguePenalty;

    return (_ctrWeight * ctr) +
        (_partnerWeight * partner) +
        (_affinityWeight * affinity) -
        fatigue;
  }

  AdService._();
  static final AdService instance = AdService._();

  static const double _epsilon = 0.20; // 20% explore randomly
  static const int _capPerPlacement = 50;

  // Freshness: penalize older creatives slightly so new/updated ads get a chance.
  // Score = smoothedCTR - ageDays * _agePenaltyPerDay
  static const double _agePenaltyPerDay = 0.005; // tune 0.002–0.01
  final Random _rng = Random();

  // --- Session frequency cap ---
  // Max impressions per adId within the current app session.
  static const int _sessionCapPerAd = 3;
  final Map<String, int> _sessionImp = <String, int>{};

  String _sessKey(String placement, String id) => 'sess::$placement::$id';
  int _sessCount(String placement, String id) =>
      _sessionImp[_sessKey(placement, id)] ?? 0;
  void _incSess(String placement, String id) {
    final k = _sessKey(placement, id);
    _sessionImp[k] = (_sessionImp[k] ?? 0) + 1;
  }

  bool _underSessCap(String placement, String id) {
    return _sessCount(placement, id) < _sessionCapPerAd;
  }

  // In-memory cache for stats to avoid repeated SharedPreferences reads.
  // Key format: "<placement>::<adId>"
  final Map<String, _AdStats> _statsCache = <String, _AdStats>{};

  /// Inventory (later: remote).
  /// Keep Amex/Mastercard/Visa present (SAS-related content rule).
  List<AdSlot> getCreative() => const <AdSlot>[
        AdSlot(
          id: 'amex_sas_1',
          title: 'Amex: høy poengopptjening',
          body: 'Bruk Amex på hverdagskjøp og bygg poeng raskere.',
          cta: 'Se tilbud',
          link: 'https://www.americanexpress.com/',
          tags: ['cards', 'amex', 'elite'],
        ),
        AdSlot(
          id: 'visa_sas_1',
          title: 'Visa: trygt og bredt akseptert',
          body: 'Se fordeler og kampanjer hos partnere.',
          cta: 'Sjekk kort',
          link: 'https://www.visa.com/',
          tags: ['cards', 'visa'],
        ),
        AdSlot(
          id: 'mc_sas_1',
          title: 'Mastercard: sterke fordeler',
          body: 'Se fordeler som kan gi mer verdi i hverdagen.',
          cta: 'Se fordeler',
          link: 'https://www.mastercard.com/',
          tags: ['cards', 'mastercard'],
        ),
        AdSlot(
          id: 'shopping_boost_1',
          title: 'Ekstra poeng-kampanjer i dag',
          body: 'Sjekk butikker med høy rate akkurat nå.',
          cta: 'Åpne',
          link: 'https://onlineshopping.flysas.com/',
          tags: ['shopping', 'campaign'],
        ),
      ];

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // --- Daily caps (persisted) ---
  // Max impressions per adId per day (per placement).
  // Max total impressions per placement per day.
  String _dayStamp(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _impDayKey(String placement, String id, String day) =>
      'ad_imp_day::$day::$placement::$id';
  String _impPlacementDayKey(String placement, String day) =>
      'ad_imp_place_day::$day::$placement';

  Future<int> _getDayImpressions(String placement, String id) async {
    final prefs = await _prefs();
    final day = _dayStamp(DateTime.now());
    return prefs.getInt(_impDayKey(placement, id, day)) ?? 0;
  }

  Future<int> _getPlacementDayImpressions(String placement) async {
    final prefs = await _prefs();
    final day = _dayStamp(DateTime.now());
    return prefs.getInt(_impPlacementDayKey(placement, day)) ?? 0;
  }

  String _impKey(String placement, String id) => 'ad_imp::$placement::$id';
  String _clkKey(String placement, String id) => 'ad_clk::$placement::$id';

  String _tsKey(String placement, String id) => 'ad_ts::$placement::$id';

  int _getLastSeenMsFromPrefs(
      SharedPreferences prefs, String placement, String id) {
    // 0 => never seen (treated as very fresh)
    return prefs.getInt(_tsKey(placement, id)) ?? 0;
  }

  Future<void> _touchLastSeen({
    required String placement,
    required String adId,
  }) async {
    final prefs = await _prefs();
    await prefs.setInt(
        _tsKey(placement, adId), DateTime.now().millisecondsSinceEpoch);
  }

  String _cacheKey(String placement, String id) => '$placement::$id';

  _AdStats _getStatsFromPrefs(
      SharedPreferences prefs, String placement, String id) {
    final ck = _cacheKey(placement, id);
    final cached = _statsCache[ck];
    if (cached != null) return cached;

    final imp = prefs.getInt(_impKey(placement, id)) ?? 0;
    final clk = prefs.getInt(_clkKey(placement, id)) ?? 0;
    final stats = _AdStats(imp, clk);
    _statsCache[ck] = stats;
    return stats;
  }

  void _bumpCacheImpression(String placement, String id) {
    final ck = _cacheKey(placement, id);
    final cur = _statsCache[ck];
    if (cur == null) return;
    _statsCache[ck] = _AdStats(cur.impressions + 1, cur.clicks);
  }

  void _bumpCacheClick(String placement, String id) {
    final ck = _cacheKey(placement, id);
    final cur = _statsCache[ck];
    if (cur == null) return;
    _statsCache[ck] = _AdStats(cur.impressions, cur.clicks + 1);
  }

  Future<void> recordImpression({
    required String placement,
    required String adId,
  }) async {
    _incSess(placement, adId);

    await _touchLastSeen(placement: placement, adId: adId);

    _bumpCacheImpression(placement, adId);

    final prefs = await _prefs();
    final k = _impKey(placement, adId);
    await prefs.setInt(k, (prefs.getInt(k) ?? 0) + 1);
  }

  Future<void> recordClick({
    required String placement,
    required String adId,
  }) async {
    await _touchLastSeen(placement: placement, adId: adId);

    _bumpCacheClick(placement, adId);

    final prefs = await _prefs();
    final k = _clkKey(placement, adId);
    await prefs.setInt(k, (prefs.getInt(k) ?? 0) + 1);
  }

  double _smoothedCtr(_AdStats s) {
    // Laplace smoothing: (clicks+1)/(impressions+2)
    return (s.clicks + 1) / (s.impressions + 2);
  }

  bool _matchesSegment(AdSlot a, List<String> seg) {
    if (seg.isEmpty) return true;
    final wanted = seg.map((e) => e.toLowerCase()).toSet();
    return a.tags.any((t) => wanted.contains(t.toLowerCase()));
  }

  Future<List<AdSlot>> pickAds({
    required String placement,
    int count = 1,
    List<String> requireAnyTags = const <String>[],
    List<String> segmentTags = const <String>[],
    bool enforceSessionCap = true,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final prefs = await _prefs();

    final inv = getCreative();

    var pool = inv;
    if (requireAnyTags.isNotEmpty) {
      final wanted = requireAnyTags.map((e) => e.toLowerCase()).toSet();
      pool = inv
          .where((a) => a.tags.any((t) => wanted.contains(t.toLowerCase())))
          .toList();
    }

    if (segmentTags.isNotEmpty) {
      pool = pool.where((a) => _matchesSegment(a, segmentTags)).toList();
    }

    if (enforceSessionCap) {
      final capped = pool.where((a) => _underSessCap(placement, a.id)).toList();
      // If everything is capped this session, fall back to uncapped pool to avoid empty UI.
      if (capped.isNotEmpty) pool = capped;
    }

    // Daily caps: placement + per-ad (persisted)
    final placeImp = await _getPlacementDayImpressions(placement);
    if (8 > 0 && placeImp >= 8) {
      return const <AdSlot>[];
    }

    if (3 > 0) {
      final capped = <AdSlot>[];
      for (final a in pool) {
        final imp = await _getDayImpressions(placement, a.id);
        if (imp < 3) capped.add(a);
      }
      // If everything is capped today, return empty (keeps UI clean).
      pool = capped;
    }

    if (pool.isEmpty) return const <AdSlot>[];
    count = count.clamp(1, _capPerPlacement);

    // epsilon-greedy without replacement
    final picked = <AdSlot>[];
    final remaining = pool.toList();

    

    final day = _dayStamp(DateTime.now());

    int deliveredTodayFor(AdSlot ad) =>
        prefs.getInt(_impDayKey(placement, ad.id, day)) ?? 0;

    int underDeliveredFor(AdSlot ad) {
      if (ad.guaranteePerDay <= 0) return 0;
      final need = ad.guaranteePerDay - deliveredTodayFor(ad);
      return need > 0 ? need : 0;
    }

while (picked.length < count && remaining.isNotEmpty) {
      // HARD guarantee: if under-delivered sponsored ads exist, serve them first.
      if (_hardGuarantee) {
        int bestIdx = -1;
        int bestNeed = 0;
        for (var i = 0; i < remaining.length; i++) {
          final ad = remaining[i];
          if (!ad.isSponsored || ad.guaranteePerDay <= 0) continue;
          final need = underDeliveredFor(ad);
          if (need > bestNeed) {
            bestNeed = need;
            bestIdx = i;
          }
        }
        if (bestIdx >= 0) {
          picked.add(remaining.removeAt(bestIdx));
          continue;
        }
      }


      final explore = _rng.nextDouble() < _epsilon;

      if (explore) {
        // random
        final idx = _rng.nextInt(remaining.length);
        picked.add(remaining.removeAt(idx));
        continue;
      }

      // exploit: highest smoothed CTR
      double bestScore = -1;
      int bestIdx = 0;

      for (var i = 0; i < remaining.length; i++) {
        final ad = remaining[i];
        final stats = _getStatsFromPrefs(prefs, placement, ad.id);
        final base = _smoothedCtr(stats);
        final lastMs = _getLastSeenMsFromPrefs(prefs, placement, ad.id);
        final ageDays = (lastMs <= 0) ? 0.0 : ((nowMs - lastMs) / 86400000.0);
        
        final need = underDeliveredFor(ad);
        final needRatio = ad.guaranteePerDay > 0 ? (need / ad.guaranteePerDay) : 0.0;
        final guaranteeBonus =
            (ad.isSponsored && ad.guaranteePerDay > 0) ? (_guaranteeWeight * needRatio) : 0.0;

        final score = (base - (ageDays * _agePenaltyPerDay)) + guaranteeBonus;
if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }

      picked.add(remaining.removeAt(bestIdx));
    }

    // Smart ad ordering (score desc) using real CTR + freshness + session exposure
    final prefs2 = await _prefs();
    final now = DateTime.now();

    final ctrById = <String, double>{};
    final recencyById = <String, double>{};
    final sessionById = <String, int>{};

    for (final ad in picked) {
      // NOTE: assumes AdSlot has `id` and `tags`.
      ctrById[ad.id] = await _metrics.ctr(ad.id);
      sessionById[ad.id] = _sessCount(placement, ad.id);

      final lastSeenMs = _getLastSeenMsFromPrefs(prefs2, placement, ad.id);
      final ageDays = lastSeenMs == 0
          ? 0.0
          : (now.millisecondsSinceEpoch - lastSeenMs) / 86400000.0;

      // 1.0 = fresh, 0.0 = stale (clamped)
      final freshness = (1.0 - (ageDays * _agePenaltyPerDay)).clamp(0.0, 1.0);
      recencyById[ad.id] = freshness;
    }

    picked.sort((a, b) {
      final ctrA = ctrById[a.id] ?? 0.0;
      final ctrB = ctrById[b.id] ?? 0.0;

      final sessA = sessionById[a.id] ?? 0;
      final sessB = sessionById[b.id] ?? 0;

      final freshA = recencyById[a.id] ?? 1.0;
      final freshB = recencyById[b.id] ?? 1.0;

      final scoreA = _smartScore(
            ctr: ctrA,
            tags: a.tags,
            sessionExposure: sessA,
          ) +
          (_recencyWeight * freshA);

      final scoreB = _smartScore(
            ctr: ctrB,
            tags: b.tags,
            sessionExposure: sessB,
          ) +
          (_recencyWeight * freshB);

      return scoreB.compareTo(scoreA);
    });
    return picked;
  }
}
