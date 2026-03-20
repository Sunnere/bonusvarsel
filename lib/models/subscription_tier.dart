enum SubscriptionTier {
  free,
  pro,
  elite,
}

extension SubscriptionTierX on SubscriptionTier {
  String get name => toString().split('.').last;

  /// Kort label til UI (dropdown etc.)
  String get label {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.elite:
        return 'Elite';
    }
  }

  /// Litt “marketing” tittel til paywall/premium
  String get title {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Premium';
      case SubscriptionTier.elite:
        return 'Tech / Elite';
    }
  }

  /// Parse fra lagret string ("free"/"pro"/"elite"). Fallback = free.
  static SubscriptionTier fromName(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'elite':
        return SubscriptionTier.elite;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }
}
