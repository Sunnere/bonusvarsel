class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );
}
