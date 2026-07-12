/// Thrown when a document file cannot be converted to plain text.
class DocumentImportException implements Exception {
  const DocumentImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
