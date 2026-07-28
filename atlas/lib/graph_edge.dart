class GraphEdge {
  const GraphEdge({
    required this.from,
    required this.to,
    required this.type,
  });

  final String from;
  final String to;
  final String type;

  @override
  String toString() => '$from -[$type]-> $to';
}