#!/usr/bin/env bash
set -euo pipefail

mkdir -p tool

cat > tool/reset_onboarding.dart <<'DART'
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('onboarding_completed_v1');
  await prefs.remove('onboarding_dismissed_premium_v1');
  await prefs.remove('onboarding_started_v1');

  print('Onboarding-flagg nullstilt.');
  print('Lukk appen helt og åpne den igjen.');
}
DART

echo "Opprettet tool/reset_onboarding.dart"
echo
echo "Kjør nå:"
echo "  flutter pub run tool/reset_onboarding.dart"
