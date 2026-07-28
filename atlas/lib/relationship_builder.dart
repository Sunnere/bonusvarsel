import 'package:atlas/graph_edge.dart';
import 'package:atlas/import_reference.dart';

/// Converts discovered import relationships into graph edges.
class RelationshipBuilder {
  const RelationshipBuilder();

  List<GraphEdge> build(
    Iterable<ImportReference> imports,
  ) {
    final edges = <GraphEdge>[];

    for (final import in imports) {
      edges.add(
        GraphEdge(
          from: import.source,
          to: import.target,
          type: 'import',
        ),
      );
    }

    return List.unmodifiable(edges);
  }
}