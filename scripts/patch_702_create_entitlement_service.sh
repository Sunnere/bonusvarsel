#!/usr/bin/env bash
set -e

FILE="lib/services/entitlement_service.dart"

cat > "$FILE" <<'DART'
class EntitlementService {
  static final EntitlementService instance = EntitlementService._();
  EntitlementService._();

  String _plan = 'free';

  String get plan => _plan;

  void unlock(String productId) {
    if (productId.contains('elite')) {
      _plan = 'elite';
    } else if (productId.contains('premium')) {
      _plan = 'premium';
    }
  }

  bool get isPremium => _plan == 'premium' || _plan == 'elite';
  bool get isElite => _plan == 'elite';
}
DART

echo "✅ EntitlementService laget"
