import 'file_info.dart';

class RepositoryModel {
  const RepositoryModel({
    required this.rootPath,
    required this.files,
    required this.totalDirectories,
    required this.scanDuration,
  });

  final String rootPath;
  final List<FileInfo> files;
  final int totalDirectories;
  final Duration scanDuration;

  int get totalFiles => files.length;

  Map<String, int> get languages {
    final map = <String, int>{};

    for (final file in files) {
      map.update(
        file.language,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return map;
  }
}