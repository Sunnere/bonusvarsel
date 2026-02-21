import 'package:shared_preferences/shared_preferences.dart';

class UserState {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> _p() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  static const _kSelectedCardId = 'selected_card_id';
  static const _kSelectedCardRate = 'selected_card_rate_per_100';

  static Future<void> setSelectedCard(String id, double ratePer100) async {
    final prefs = await _p();
    await prefs.setString(_kSelectedCardId, id);
    await prefs.setDouble(_kSelectedCardRate, ratePer100);
  }

  static Future<String?> getSelectedCardId() async {
    final prefs = await _p();
    return prefs.getString(_kSelectedCardId);
  }

  static Future<double?> getSelectedCardRatePer100() async {
    final prefs = await _p();
    return prefs.getDouble(_kSelectedCardRate);
  }

  // (valgfritt) enkel reset hvis du trenger
  static Future<void> clearSelectedCard() async {
    final prefs = await _p();
    await prefs.remove(_kSelectedCardId);
    await prefs.remove(_kSelectedCardRate);
  }
}
