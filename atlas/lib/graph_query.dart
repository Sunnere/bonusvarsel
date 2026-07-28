import 'graph_edge.dart';
import 'knowledge_graph.dart';

/// Read-only query API for a [KnowledgeGraph].
///
/// This class never modifies the graph. Its responsibility is to answer
/// questions about relationships between nodes.
class GraphQuery {
  const GraphQuery(this.graph);

  final KnowledgeGraph graph;

  /// Returns all outgoing import edges from [nodeId].
  List<GraphEdge> importsOf(String nodeId) {
    return graph.edges
        .where(
          (edge) => edge.from == nodeId && edge.type == 'import',
        )
        .toList(growable: false);
  }

  /// Returns all incoming import edges to [nodeId].
  List<GraphEdge> importedBy(String nodeId) {
    return graph.edges
        .where(
          (edge) => edge.to == nodeId && edge.type == 'import',
        )
        .toList(growable: false);
  }

  /// Alias for [importsOf].
  List<GraphEdge> dependenciesOf(String nodeId) {
    return importsOf(nodeId);
  }

  /// Alias for [importedBy].
  List<GraphEdge> dependentsOf(String nodeId) {
    return importedBy(nodeId);
  }
}