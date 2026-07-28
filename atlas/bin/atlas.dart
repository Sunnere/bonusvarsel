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
  final query = scanner.query;

  if (inventory != null && graph != null && query != null) {
    print('');
    print('Knowledge Graph');
    print('---------------');
    print('Files   : ${inventory.totalFiles}');
    print('Nodes   : ${graph.nodeCount}');
    print('Edges   : ${graph.edgeCount}');
    print('Imports : ${scanner.imports.length}');

    final sample = graph.nodes.firstWhere(
      (node) => query.importsOf(node.id).isNotEmpty,
      orElse: () => graph.nodes.first,
    );

    final imports = query.importsOf(sample.id);

    print('');
    print('Graph Query');
    print('-----------');
    print('Sample node : ${sample.name}');
    print('Imports     : ${imports.length}');

    for (final edge in imports.take(5)) {
      print('  -> ${edge.to}');
    }

    if (imports.length > 5) {
      print('  ... (${imports.length - 5} more)');
    }
  }

  print('');
  print('✅ Atlas finished successfully.');
}