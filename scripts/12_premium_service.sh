#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/premium_service.dart"
mkdir -p lib/services

cat > "$FILE" <<'DART'
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const _kIsPremium = 'is_premium';

  const PremiumService();

  Future<bool> getIsPremium() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kIsPremium) ?? false;
  }

  Future<void> setIsPremium(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIsPremium, v);
  }
}
DART

dart format "$FILE"
flutter analyze
