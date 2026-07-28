import 'dart:io';

import 'package:atlas/file_filters.dart';
import 'package:atlas/graph_builder.dart';
import 'package:atlas/graph_query.dart';
import 'package:atlas/import_reference.dart';
import 'package:atlas/import_scanner.dart';
import 'package:atlas/knowledge_graph.dart';
import 'package:atlas/repository_inventory.dart';
import 'package:atlas/repository_item.dart';
import 'package:atlas/repository_stats.dart';

class RepositoryScanner {
  RepositoryScanner({
    required this.repositoryRoot,
  });

  final String repositoryRoot;

  final ImportScanner _importScanner = const ImportScanner();

  RepositoryInventory? _inventory;
  KnowledgeGraph? _graph;
  GraphQuery? _query;
  List<ImportReference> _imports = const [];

  RepositoryInventory? get inventory => _inventory;

  KnowledgeGraph? get graph => _graph;

  GraphQuery? get query => _query;

  List<ImportReference> get imports => _imports;

  Future<RepositoryStats> scan() async {
    final root = Directory(repositoryRoot);

    final inventory = RepositoryInventory();
    final imports = <ImportReference>[];

    await for (final entity
        in root.list(recursive: true, followLinks: false)) {
      final path = entity.path;

      if (FileFilters.shouldIgnore(path)) {
        continue;
      }

      if (entity is! File) {
        continue;
      }

      inventory.add(
        RepositoryItem(
          path: path,
        ),
      );

      if (path.endsWith('.dart')) {
        imports.addAll(
          _importScanner.scan(entity),
        );
      }
    }

    _inventory = inventory;
    _imports = List.unmodifiable(imports);

    final graph = const GraphBuilder().build(
      inventory,
      imports: imports,
    );

    _graph = graph;
    _query = GraphQuery(graph);

    return RepositoryStats(
      directories: Directory(repositoryRoot)
          .listSync(recursive: true)
          .whereType<Directory>()
          .where((d) => !FileFilters.shouldIgnore(d.path))
          .length,
      dartFiles:
          inventory.items.where((e) => e.extension == '.dart').length,
      testFiles: inventory.tests.length,
      pubspecFiles: inventory.configs
          .where((e) => e.name == 'pubspec.yaml')
          .length,
    );
  }
}