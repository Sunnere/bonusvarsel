import 'package:atlas/graph_node.dart';
import 'package:atlas/knowledge_graph.dart';
import 'package:atlas/repository_inventory.dart';
import 'package:atlas/repository_item.dart';

/// Builds a KnowledgeGraph from a RepositoryInventory.
class GraphBuilder {
  const GraphBuilder();

  KnowledgeGraph build(RepositoryInventory inventory) {
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

    // Relationships are added in a later sprint.

    return graph;
  }
}