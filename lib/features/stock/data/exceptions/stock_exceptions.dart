// ServerException and NetworkException are imported from core/error/exceptions.dart
// Only define stock-specific exception here:

class StockInsufficientException implements Exception {
  const StockInsufficientException();
}
