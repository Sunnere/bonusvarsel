// ============================================================
// Bonusvarsel Regnskap — API Service
// Kommuniserer med backend-fiken-ai API
// lib/features/regnskap/services/regnskap_api_service.dart
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class RegnskapApiService {
  // iOS simulator: bruk Mac-ens lokale IP (ikke localhost)
  static const String _baseUrl = 'http://192.168.1.144:8787';

  // ---- Hent innsikter med AI-forklaringer ----
  Future<RegnskapInsightResult> getEnrichedInsights() async {
    final res = await http.get(Uri.parse('$_baseUrl/ai/insights/enriched'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['ok'] != true) throw Exception(data['error'] ?? 'Ukjent feil');

    return RegnskapInsightResult(
      insights: (data['insights'] as List)
          .map((i) => RegnskapInsight.fromJson(i))
          .toList(),
    );
  }

  // ---- Hent økonomicore med AI-kommentar ----
  Future<RegnskapScore> getScoreWithComment() async {
    final res = await http.get(Uri.parse('$_baseUrl/ai/score/comment'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['ok'] != true) throw Exception(data['error'] ?? 'Ukjent feil');
    return RegnskapScore.fromJson(data);
  }

  // ---- Hent dashboard-sammendrag ----
  Future<RegnskapSummary> getSummary() async {
    final res = await http.get(Uri.parse('$_baseUrl/patterns/summary'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['ok'] != true) throw Exception(data['error'] ?? 'Ukjent feil');
    return RegnskapSummary.fromJson(data['summary'] as Map<String, dynamic>);
  }

  // ---- Kjør Pattern Engine ----
  Future<Map<String, dynamic>> runPatternEngine() async {
    final res = await http.post(Uri.parse('$_baseUrl/patterns/run'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---- Dismiss innsikt ----
  Future<void> dismissInsight(String id) async {
    await http.post(Uri.parse('$_baseUrl/patterns/dismiss/$id'));
  }

  // ---- Hent abonnementsstatus ----
  Future<RegnskapSubscription> getSubscriptionStatus() async {
    final res = await http.get(Uri.parse('$_baseUrl/subscription/status'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return RegnskapSubscription.fromJson(data);
  }
}

// ---- Data-modeller ----

class RegnskapInsight {
  final String id;
  final String type;
  final String title;
  final String description;
  final String aiExplanation;
  final int score;
  final Map<String, dynamic> metadata;
  final bool isDismissed;

  const RegnskapInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.aiExplanation,
    required this.score,
    required this.metadata,
    this.isDismissed = false,
  });

  factory RegnskapInsight.fromJson(Map<String, dynamic> j) => RegnskapInsight(
    id:            j['id']?.toString() ?? '',
    type:          j['insight_type'] ?? j['type'] ?? 'general',
    title:         j['title'] ?? '',
    description:   j['description'] ?? '',
    aiExplanation: j['ai_explanation'] ?? j['description'] ?? '',
    score:         (j['score'] as num?)?.toInt() ?? 0,
    metadata:      Map<String, dynamic>.from(j['metadata'] ?? j['meta'] ?? {}),
    isDismissed:   j['is_dismissed'] == true,
  );

  String get icon {
    switch (type) {
      case 'bonus_opportunity':     return '⭐';
      case 'missing_receipt':       return '🧾';
      case 'subscription_detected': return '🔄';
      case 'cost_increase':         return '📈';
      case 'large_purchase':        return '💳';
      default:                      return '💡';
    }
  }
}

class RegnskapInsightResult {
  final List<RegnskapInsight> insights;
  const RegnskapInsightResult({required this.insights});
}

class RegnskapScore {
  final int score;
  final String label;
  final String color;
  final String? comment;
  final List<ScoreBreakdown> breakdown;

  const RegnskapScore({
    required this.score,
    required this.label,
    required this.color,
    this.comment,
    required this.breakdown,
  });

  factory RegnskapScore.fromJson(Map<String, dynamic> j) => RegnskapScore(
    score:     (j['score'] as num?)?.toInt() ?? 0,
    label:     j['label'] ?? '',
    color:     j['color'] ?? '#868CFF',
    comment:   j['comment'],
    breakdown: (j['breakdown'] as List? ?? [])
        .map((b) => ScoreBreakdown.fromJson(b))
        .toList(),
  );
}

class ScoreBreakdown {
  final String category;
  final int score;
  final int max;
  final String detail;
  const ScoreBreakdown({required this.category, required this.score, required this.max, required this.detail});
  factory ScoreBreakdown.fromJson(Map<String, dynamic> j) => ScoreBreakdown(
    category: j['category'] ?? '',
    score:    (j['score'] as num?)?.toInt() ?? 0,
    max:      (j['max'] as num?)?.toInt() ?? 100,
    detail:   j['detail'] ?? '',
  );
}

class RegnskapSummary {
  final int subscriptionCount;
  final int costIncreaseCount;
  final int missingReceiptCount;
  final int potentialBonusPoints;
  final int totalInsights;

  const RegnskapSummary({
    required this.subscriptionCount,
    required this.costIncreaseCount,
    required this.missingReceiptCount,
    required this.potentialBonusPoints,
    required this.totalInsights,
  });

  factory RegnskapSummary.fromJson(Map<String, dynamic> j) => RegnskapSummary(
    subscriptionCount:    (j['subscription_count'] as num?)?.toInt() ?? 0,
    costIncreaseCount:    (j['cost_increase_count'] as num?)?.toInt() ?? 0,
    missingReceiptCount:  (j['missing_receipt_count'] as num?)?.toInt() ?? 0,
    potentialBonusPoints: (j['potential_bonus_points'] as num?)?.toInt() ?? 0,
    totalInsights:        (j['total_insights'] as num?)?.toInt() ?? 0,
  );
}

class RegnskapSubscription {
  final String tier;
  final bool isActive;
  final bool fikenIntegration;
  final bool excelExport;

  const RegnskapSubscription({
    required this.tier,
    required this.isActive,
    required this.fikenIntegration,
    required this.excelExport,
  });

  factory RegnskapSubscription.fromJson(Map<String, dynamic> j) {
    final features = j['features'] as Map<String, dynamic>? ?? {};
    return RegnskapSubscription(
      tier:              j['tier'] ?? 'free',
      isActive:          j['is_active'] == true,
      fikenIntegration:  features['fiken_integration'] == true,
      excelExport:       features['excel_export'] == true,
    );
  }

  bool get isPro   => tier == 'pro'   || tier == 'elite';
  bool get isElite => tier == 'elite';
}
