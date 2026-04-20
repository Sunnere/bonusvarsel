import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('onboarding_completed_v1');
  await prefs.remove('onboarding_dismissed_premium_v1');
  await prefs.remove('onboarding_started_v1');

  stdout.writeln('Onboarding-flagg nullstilt.');
  stdout.writeln('Lukk appen helt og åpne den igjen.');
}
