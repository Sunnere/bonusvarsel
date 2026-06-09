import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    return 'https://bonusvarsel-production.up.railway.app';
  }

  static bool get isConfigured => baseUrl.isNotEmpty;
}
