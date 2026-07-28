import 'dart:io';

import 'package:atlas/file_filters.dart';
import 'package:atlas/graph_builder.dart';
import 'package:atlas/knowledge_graph.dart';
import 'package:atlas/repository_inventory.dart';
import 'package:atlas/repository_item.dart';
import 'package:atlas/repository_stats.dart';

class RepositoryScanner {
  RepositoryScanner({
    required this.repositoryRoot,
  });

  final String repositoryRoot;

  RepositoryInventory? _inventory;
  KnowledgeGraph? _graph;

  RepositoryInventory? get inventory => _inventory;

  KnowledgeGraph? get graph => _graph;

  Future<RepositoryStats> scan() async {
    final root = Directory(repositoryRoot);

    final inventory = RepositoryInventory();

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
    }

    _inventory = inventory;
    _graph = const GraphBuilder().build(inventory);

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