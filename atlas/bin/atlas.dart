import 'dart:io';

import 'package:atlas/reporters/console_reporter.dart';
import 'package:atlas/repository_scanner.dart';

Future<void> main(List<String> args) async {
  print('');
  print('====================================');
  print('      🚀 Atlas Engineering OS');
  print('====================================');
  print('');

  final atlasDir = Directory.current;
  final repositoryRoot = atlasDir.parent.path;

  print('Atlas      : ${atlasDir.path}');
  print('Repository : $repositoryRoot');
  print('');

  final scanner = RepositoryScanner(
    repositoryRoot: repositoryRoot,
  );

  final stats = await scanner.scan();

  ConsoleReporter().printSummary(stats);

  final inventory = scanner.inventory;
  final graph = scanner.graph;

  if (inventory != null && graph != null) {
    print('');
    print('Knowledge Graph');
    print('---------------');
    print('Files : ${inventory.totalFiles}');
    print('Nodes : ${graph.nodeCount}');
  }

  print('');
  print('✅ Atlas finished successfully.');
}