
class FileHandlingException implements Exception {
  final String message;

  const FileHandlingException(this.message);

  @override
  String toString() => message;
}
