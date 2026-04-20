import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _completedKey = 'onboarding_completed_v1';
  static const String _dismissedPremiumKey = 'onboarding_dismissed_premium_v1';
  static const String _startedKey = 'onboarding_started_v1';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_startedKey, true);
  }

  static Future<bool> hasStarted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_startedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  static Future<void> dismissPremiumForNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedPremiumKey, true);
  }

  static Future<bool> dismissedPremiumForNow() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedPremiumKey) ?? false;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
    await prefs.remove(_dismissedPremiumKey);
    await prefs.remove(_startedKey);
  }
}
