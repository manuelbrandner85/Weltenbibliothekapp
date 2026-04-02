/// Weltenbibliothek - Recherche Exception
/// 
/// Custom Exception für Recherche-Fehler
library;

class RechercheException implements Exception {
  final String message;
  final String? details;
  final Object? originalError;

  RechercheException(
    this.message, {
    this.details,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('RechercheException: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (originalError != null) {
      buffer.write('\nOriginal Error: $originalError');
    }
    return buffer.toString();
  }
}
