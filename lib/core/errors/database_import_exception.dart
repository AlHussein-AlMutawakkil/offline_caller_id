class DatabaseImportException implements Exception {
  final String message;

  const DatabaseImportException(this.message);

  @override
  String toString() => message;
}
