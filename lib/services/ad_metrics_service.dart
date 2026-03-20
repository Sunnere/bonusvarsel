import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdMetricsService {
  static const _kClicks = 'ad_metrics_clicks_v1';
  static const _kImpr = 'ad_metrics_impressions_v1';

  Map<String, int> _clicks = {};
  Map<String, int> _impressions = {};
  bool _loaded = false;

  Future<void> _loadOnce() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final clicksRaw = prefs.getString(_kClicks);
    final imprRaw = prefs.getString(_kImpr);

    _clicks = _decodeMap(clicksRaw);
    _impressions = _decodeMap(imprRaw);
    _loaded = true;
  }

  Map<String, int> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final obj = jsonDecode(raw);
      if (obj is Map) {
        return obj.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kClicks, jsonEncode(_clicks));
    await prefs.setString(_kImpr, jsonEncode(_impressions));
  }

  Future<void> recordImpression(String adId) async {
    await _loadOnce();
    _impressions[adId] = (_impressions[adId] ?? 0) + 1;
    await _persist();
  }

  Future<void> recordClick(String adId) async {
    await _loadOnce();
    _clicks[adId] = (_clicks[adId] ?? 0) + 1;
    await _persist();
  }

  Future<double> ctr(String adId) async {
    await _loadOnce();
    final impr = (_impressions[adId] ?? 0);
    if (impr <= 0) return 0.0;
    final clk = (_clicks[adId] ?? 0);
    return clk / impr;
  }

  // --- Debug helpers ---
  Future<Map<String, int>> clicksSnapshot() async {
    await _loadOnce();
    return Map<String, int>.from(_clicks);
  }

  Future<Map<String, int>> impressionsSnapshot() async {
    await _loadOnce();
    return Map<String, int>.from(_impressions);
  }

  Future<void> resetAll() async {
    await _loadOnce();
    _clicks = {};
    _impressions = {};
    await _persist();
  }

}
