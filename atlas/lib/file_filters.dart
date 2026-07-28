import 'package:path/path.dart' as p;

class FileFilters {
  static const Set<String> ignoredDirectories = {
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    '.firebase',
    'build',
    'Pods',
    'node_modules',
    'coverage',
    '.next',
    '.turbo',
    'dist',
    'out',
  };

  static bool shouldIgnore(String path) {
    final parts = p.split(path);

    return parts.any(ignoredDirectories.contains);
  }

  static bool shouldScan(String path) {
    return !shouldIgnore(path);
  }

  static bool isDartFile(String path) {
    return path.endsWith('.dart');
  }

  static bool isTestFile(String path) {
    return path.endsWith('_test.dart');
  }

  static bool isPubspec(String path) {
    return p.basename(path) == 'pubspec.yaml';
  }
}