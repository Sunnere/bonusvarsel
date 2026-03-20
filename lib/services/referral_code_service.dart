import 'package:shared_preferences/shared_preferences.dart';

class ReferralCodeService {
  static const _kKey = 'bv.referral.code';

  const ReferralCodeService();

  Future<String?> getCode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kKey);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  Future<void> setCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, code.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}
