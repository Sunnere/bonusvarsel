class LanguageDetector {
  static String detect(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return 'Dart';

      case '.yaml':
      case '.yml':
        return 'YAML';

      case '.json':
        return 'JSON';

      case '.md':
        return 'Markdown';

      default:
        return 'Other';
    }
  }
}