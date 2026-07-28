class ImportReference {
  const ImportReference({
    required this.source,
    required this.target,
  });

  final String source;
  final String target;

  @override
  String toString() => '$source -> $target';
}