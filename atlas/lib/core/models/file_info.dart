class FileInfo {
  const FileInfo({
    required this.path,
    required this.extension,
    required this.size,
    required this.language,
  });

  final String path;
  final String extension;
  final int size;
  final String language;
}