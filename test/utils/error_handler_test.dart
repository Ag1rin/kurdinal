import 'package:flutter_test/flutter_test.dart';
import 'package:kurdinal/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('should return user-friendly message for network errors', () {
      final error = Exception('SocketException: Failed host lookup');
      final message = ErrorHandler.getErrorMessage(error);
      
      expect(message, contains('Network connection error'));
    });

    test('should return user-friendly message for timeout errors', () {
      final error = Exception('TimeoutException');
      final message = ErrorHandler.getErrorMessage(error);
      
      expect(message, contains('timed out'));
    });

    test('should return user-friendly message for JSON errors', () {
      final error = Exception('FormatException: Invalid JSON');
      final message = ErrorHandler.getErrorMessage(error);
      
      expect(message, contains('Invalid data format'));
    });

    test('should return user-friendly message for wallet errors', () {
      final error = Exception('Invalid wallet format');
      final message = ErrorHandler.getErrorMessage(error);
      
      expect(message, contains('Invalid wallet file'));
    });

    test('should identify retryable errors', () {
      final networkError = Exception('Network error');
      final walletError = Exception('Invalid wallet');
      
      expect(ErrorHandler.isRetryable(networkError), isTrue);
      expect(ErrorHandler.isRetryable(walletError), isFalse);
    });

    test('should return appropriate error title', () {
      final networkError = Exception('Network error');
      final walletError = Exception('Wallet error');
      
      expect(ErrorHandler.getErrorTitle(networkError), 'Connection Error');
      expect(ErrorHandler.getErrorTitle(walletError), 'Wallet Error');
    });
  });
}

