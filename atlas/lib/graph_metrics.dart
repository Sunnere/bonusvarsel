import 'graph_query.dart';
import 'knowledge_graph.dart';

class GraphMetrics {
  const GraphMetrics({
    required this.graph,
    required this.query,
  });

  final KnowledgeGraph graph;
  final GraphQuery query;

  List<MapEntry<String, int>> mostImported() {
    final results = graph.nodes.map((node) {
      final count = query.importedBy(node.id).length;
      return MapEntry(node.id, count);
    }).toList();

    results.sort((a, b) => b.value.compareTo(a.value));

    return List.unmodifiable(results);
  }

  List<MapEntry<String, int>> mostDependencies() {
    final results = graph.nodes.map((node) {
      final count = query.dependenciesOf(node.id).length;
      return MapEntry(node.id, count);
    }).toList();

    results.sort((a, b) => b.value.compareTo(a.value));

    return List.unmodifiable(results);
  }

  List<String> leafNodes() {
    final results = graph.nodes
        .where((node) => query.dependenciesOf(node.id).isEmpty)
        .map((node) => node.id)
        .toList();

    results.sort();

    return List.unmodifiable(results);
  }

  List<String> rootNodes() {
    final results = graph.nodes
        .where((node) => query.importedBy(node.id).isEmpty)
        .map((node) => node.id)
        .toList();

    results.sort();

    return List.unmodifiable(results);
  }

  List<String> isolatedNodes() {
    final results = graph.nodes
        .where(
          (node) =>
              query.dependenciesOf(node.id).isEmpty &&
              query.importedBy(node.id).isEmpty,
        )
        .map((node) => node.id)
        .toList();

    results.sort();

    return List.unmodifiable(results);
  }
}