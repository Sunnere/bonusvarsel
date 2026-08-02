import 'dart:io';

import '../core/models/file_info.dart';
import '../core/models/repository_model.dart';
import 'language_detector.dart';

class RepositoryScanner {
  Future<RepositoryModel> scan(String rootPath) async {
    final stopwatch = Stopwatch()..start();

    final files = <FileInfo>[];
    var directories = 0;

    await for (final entity
        in Directory(rootPath).list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        directories++;
        continue;
      }

      if (entity is! File) continue;

      final extension = _extension(entity.path);

      files.add(
        FileInfo(
          path: entity.path,
          extension: extension,
          size: await entity.length(),
          language: LanguageDetector.detect(extension),
        ),
      );
    }

    stopwatch.stop();

    return RepositoryModel(
      rootPath: rootPath,
      files: files,
      totalDirectories: directories,
      scanDuration: stopwatch.elapsed,
    );
  }

  String _extension(String path) {
    final index = path.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return path.substring(index);
  }
}