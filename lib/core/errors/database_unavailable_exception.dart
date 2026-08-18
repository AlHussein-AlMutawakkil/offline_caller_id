class DatabaseUnavailableException implements Exception {
  final String message;

  const DatabaseUnavailableException(this.message);

  @override
  String toString() => message;
}
