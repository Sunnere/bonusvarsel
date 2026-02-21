class FeatureGating {
  const FeatureGating._();

  /// Hvor mange elementer som skal vises gitt premium/freeLimit
  static int visibleCount({
    required bool isPremium,
    required int freeLimit,
    required int total,
  }) {
    if (total <= 0) return 0;
    if (isPremium) return total;
    final lim = freeLimit < 0 ? 0 : freeLimit;
    return lim > total ? total : lim;
  }

  static bool isGated({
    required bool isPremium,
    required int freeLimit,
    required int total,
  }) {
    return !isPremium &&
        total >
            visibleCount(
                isPremium: isPremium, freeLimit: freeLimit, total: total);
  }
}
