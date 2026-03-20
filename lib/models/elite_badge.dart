// Generated/standardized by scripts/150_fix_elite_badge_model_and_optional_params.sh
// Canonical badge/tier model used by UI widgets.

enum EliteBadge { elite }

extension EliteBadgeX on EliteBadge {
  String get label {
    switch (this) {
      case EliteBadge.elite:
        return 'Elite';
    }
  }
}
