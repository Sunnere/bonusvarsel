/// Represents a single node in the Atlas Knowledge Graph.
///
/// A node corresponds to one RepositoryItem. Relationships between
/// nodes will be introduced in a later sprint.
class GraphNode {
  const GraphNode({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Relative repository path.
  final String path;

  /// Node classification (page, widget, service, etc.).
  final String type;

  @override
  String toString() {
    return 'GraphNode(id: $id, type: $type, path: $path)';
  }
}