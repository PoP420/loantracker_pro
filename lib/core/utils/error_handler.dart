// lib/core/utils/error_handler.dart

import 'package:flutter/foundation.dart';

/// Enhanced error handler for common Flutter/Dart exceptions
class ErrorHandler {
  /// Handles "Bad state: No element" and similar collection errors
  static T? handleCollectionError<T>(T Function() operation,
      {T? defaultValue}) {
    try {
      return operation();
    } on StateError catch (e) {
      if (kDebugMode) {
        print('Collection StateError caught: ${e.message}');
      }
      return defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in collection operation: $e');
      }
      return defaultValue;
    }
  }

  /// Handles RangeError for index operations
  static T? handleIndexError<T>(T Function() operation, {T? defaultValue}) {
    try {
      return operation();
    } on RangeError catch (e) {
      if (kDebugMode) {
        print('RangeError caught: ${e.message}');
      }
      return defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in index operation: $e');
      }
      return defaultValue;
    }
  }

  /// Generic error handler for any operation
  static T? handleError<T>(T Function() operation,
      {T? defaultValue, bool silent = false}) {
    try {
      return operation();
    } catch (e) {
      if (!silent && kDebugMode) {
        print('Error caught: $e');
      }
      return defaultValue;
    }
  }

  /// Handles async operations with error catching
  static Future<T?> handleAsyncError<T>(Future<T> Function() operation,
      {T? defaultValue}) async {
    try {
      return await operation();
    } catch (e) {
      if (kDebugMode) {
        print('Async error caught: $e');
      }
      return defaultValue;
    }
  }

  /// Categorizes error types for better handling
  static String getErrorCategory(dynamic error) {
    if (error is StateError) {
      if (error.message.contains('No element')) {
        return 'empty_collection';
      }
      return 'state_error';
    } else if (error is RangeError) {
      return 'index_out_of_bounds';
    } else if (error is ArgumentError) {
      return 'invalid_argument';
    } else if (error is TypeError) {
      return 'type_error';
    } else if (error is FormatException) {
      return 'format_error';
    } else {
      return 'unknown_error';
    }
  }

  /// Gets user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    final category = getErrorCategory(error);

    switch (category) {
      case 'empty_collection':
        return 'No data available at the moment. Please try refreshing.';
      case 'index_out_of_bounds':
        return 'Unable to access the requested information.';
      case 'invalid_argument':
        return 'Invalid input provided. Please check your data.';
      case 'type_error':
        return 'Data format error. Please try again.';
      case 'format_error':
        return 'Invalid data format encountered.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
