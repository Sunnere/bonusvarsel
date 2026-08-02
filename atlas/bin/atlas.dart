import 'dart:io';

import 'package:atlas/scanner/repository_scanner.dart';

Future<void> main(List<String> args) async {
  final root = args.isEmpty ? Directory.current.path : args.first;

  final scanner = RepositoryScanner();

  print('Atlas Repository Scanner');
  print('');

  final model = await scanner.scan(root);

  print('Repository : ${model.rootPath}');
  print('Files      : ${model.totalFiles}');
  print('Directories: ${model.totalDirectories}');
  print('');

  print('Languages');

  final languages = model.languages.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (final language in languages) {
    print(' - ${language.key}: ${language.value}');
  }

  print('');
  print(
    'Completed in ${model.scanDuration.inMilliseconds} ms',
  );
}