class RepositoryStats {
  final int directories;
  final int dartFiles;
  final int testFiles;
  final int pubspecFiles;

  const RepositoryStats({
    required this.directories,
    required this.dartFiles,
    required this.testFiles,
    required this.pubspecFiles,
  });
}