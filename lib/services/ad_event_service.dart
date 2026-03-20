import 'package:flutter/foundation.dart';

class AdEventService {
  AdEventService._();

  static final Set<String> _impressed = <String>{};

  static void impression({
    required String placement,
    required String adId,
    String? tier,
  }) {
    final key = '$placement|$adId';
    if (_impressed.contains(key)) return;
    _impressed.add(key);

    if (kDebugMode) {
      debugPrint(
          '📣 AD_IMPRESSION placement=$placement adId=$adId tier=${tier ?? "-"}');
    }
  }

  static void click({
    required String placement,
    required String adId,
    String? tier,
  }) {
    if (kDebugMode) {
      debugPrint(
          '🖱️ AD_CLICK placement=$placement adId=$adId tier=${tier ?? "-"}');
    }
  }
}
