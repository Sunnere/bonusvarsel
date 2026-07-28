import 'graph_edge.dart';
import 'graph_node.dart';

/// Represents the Atlas Knowledge Graph.
class KnowledgeGraph {
  KnowledgeGraph({
    Iterable<GraphNode> nodes = const [],
    Iterable<GraphEdge> edges = const [],
  })  : _nodes = Map.fromEntries(
          nodes.map((node) => MapEntry(node.id, node)),
        ),
        _edges = List.of(edges);

  final Map<String, GraphNode> _nodes;
  final List<GraphEdge> _edges;

  /// All nodes in the graph.
  Iterable<GraphNode> get nodes => _nodes.values;

  /// All edges in the graph.
  Iterable<GraphEdge> get edges => _edges;

  /// Number of nodes.
  int get nodeCount => _nodes.length;

  /// Number of edges.
  int get edgeCount => _edges.length;

  /// Returns a node by id.
  GraphNode? getNode(String id) => _nodes[id];

  /// Adds or replaces a node.
  void addNode(GraphNode node) {
    _nodes[node.id] = node;
  }

  /// Adds an edge.
  void addEdge(GraphEdge edge) {
    _edges.add(edge);
  }

  /// Returns true if the graph contains the node.
  bool contains(String id) => _nodes.containsKey(id);
}