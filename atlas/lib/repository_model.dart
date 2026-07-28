abstract class RepositoryNode {
  String get id;
  String get name;
}

class RepositoryModel extends RepositoryNode {
  @override
  final String id = 'repository';

  @override
  final String name;

  final List<PackageNode> packages;

  RepositoryModel({
    required this.name,
    required this.packages,
  });
}

class PackageNode extends RepositoryNode {
  @override
  final String id;

  @override
  final String name;

  final List<LibraryNode> libraries;

  PackageNode({
    required this.id,
    required this.name,
    required this.libraries,
  });
}

class LibraryNode extends RepositoryNode {
  @override
  final String id;

  @override
  final String name;

  final String path;

  final List<FileNode> files;

  LibraryNode({
    required this.id,
    required this.name,
    required this.path,
    required this.files,
  });
}