/// Utility class for handling and formatting errors
class ErrorHandler {
  /// Get user-friendly error message
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // JSON parsing errors
    if (errorString.contains('json') || errorString.contains('parse')) {
      return 'Invalid data format. Please check your JSON file.';
    }

    // File errors
    if (errorString.contains('file') || errorString.contains('permission')) {
      return 'File access error. Please check file permissions.';
    }

    // Wallet errors
    if (errorString.contains('wallet') || errorString.contains('jwk')) {
      if (errorString.contains('invalid')) {
        return 'Invalid wallet file. Please ensure it is a valid Arweave JWK file.';
      }
      return 'Wallet error. Please check your wallet file.';
    }

    // Arweave errors
    if (errorString.contains('arweave') || errorString.contains('transaction')) {
      if (errorString.contains('insufficient') || errorString.contains('balance')) {
        return 'Insufficient balance. Please add AR tokens to your wallet.';
      }
      if (errorString.contains('failed') || errorString.contains('error')) {
        return 'Transaction failed. Please try again later.';
      }
      return 'Arweave service error. Please try again.';
    }

    // Storage errors
    if (errorString.contains('storage') || errorString.contains('shared_preferences')) {
      return 'Storage error. Please try again.';
    }

    // Generic error
    return 'An error occurred: ${error.toString()}';
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket');
  }

  /// Get error title
  static String getErrorTitle(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection Error';
    }
    if (errorString.contains('wallet')) {
      return 'Wallet Error';
    }
    if (errorString.contains('arweave') || errorString.contains('transaction')) {
      return 'Upload Error';
    }
    if (errorString.contains('file')) {
      return 'File Error';
    }

    return 'Error';
  }
}

