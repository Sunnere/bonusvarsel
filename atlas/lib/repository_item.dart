import 'package:path/path.dart' as p;

class RepositoryItem {
  RepositoryItem({
    required this.path,
  })  : name = p.basename(path),
        extension = p.extension(path),
        category = _detectCategory(path);

  final String path;
  final String name;
  final String extension;
  final String category;

  static String _detectCategory(String path) {
    final normalized = path.replaceAll('\\', '/');

    if (normalized.contains('/pages/')) {
      return 'page';
    }

    if (normalized.contains('/widgets/')) {
      return 'widget';
    }

    if (normalized.contains('/services/')) {
      return 'service';
    }

    if (normalized.contains('/repositories/')) {
      return 'repository';
    }

    if (normalized.contains('/models/')) {
      return 'model';
    }

    if (normalized.endsWith('_test.dart')) {
      return 'test';
    }

    if (normalized.endsWith('pubspec.yaml') ||
        normalized.endsWith('.yaml') ||
        normalized.endsWith('.json')) {
      return 'config';
    }

    if (normalized.endsWith('.sh') ||
        normalized.endsWith('.bat')) {
      return 'script';
    }

    return 'unknown';
  }

  @override
  String toString() {
    return '$category : $name';
  }
}