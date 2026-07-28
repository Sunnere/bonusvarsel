import 'package:atlas/graph_node.dart';
import 'package:atlas/import_reference.dart';
import 'package:atlas/knowledge_graph.dart';
import 'package:atlas/relationship_builder.dart';
import 'package:atlas/repository_inventory.dart';
import 'package:atlas/repository_item.dart';

/// Builds a KnowledgeGraph from a RepositoryInventory.
class GraphBuilder {
  const GraphBuilder();

  KnowledgeGraph build(
    RepositoryInventory inventory, {
    Iterable<ImportReference> imports = const [],
  }) {
    final graph = KnowledgeGraph();

    for (final RepositoryItem item in inventory.items) {
      graph.addNode(
        GraphNode(
          id: item.path,
          name: item.name,
          path: item.path,
          type: item.category,
        ),
      );
    }

    final edges = const RelationshipBuilder().build(imports);

    for (final edge in edges) {
      graph.addEdge(edge);
    }

    return graph;
  }
}