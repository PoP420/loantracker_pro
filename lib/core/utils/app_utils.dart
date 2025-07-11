import 'package:flutter/material.dart';

import './error_handler.dart';
import './safe_collection_utils.dart';

// lib/core/utils/app_utils.dart

/// General utility functions for the app
class AppUtils {
  /// Safely formats currency values
  static String formatCurrency(dynamic value, {String symbol = '₱'}) {
    return ErrorHandler.handleError(
          () {
            if (value == null) return '$symbol 0.00';

            double amount;
            if (value is String) {
              amount = double.tryParse(value) ?? 0.0;
            } else if (value is num) {
              amount = value.toDouble();
            } else {
              amount = 0.0;
            }

            return '$symbol ${amount.toStringAsFixed(2)}';
          },
          defaultValue: '$symbol 0.00',
        ) ??
        '$symbol 0.00';
  }

  /// Safely formats dates
  static String formatDate(dynamic date, {String format = 'MMM dd, yyyy'}) {
    return ErrorHandler.handleError(
          () {
            DateTime dateTime;
            if (date is String) {
              dateTime = DateTime.tryParse(date) ?? DateTime.now();
            } else if (date is DateTime) {
              dateTime = date;
            } else {
              return 'Invalid date';
            }

            // Simple date formatting (you can enhance this with intl package)
            return '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
          },
          defaultValue: 'Invalid date',
        ) ??
        'Invalid date';
  }

  /// Safely gets status color
  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'success':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'overdue':
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// Safely validates email format
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Safely validates phone number format
  static bool isValidPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    return RegExp(r'^[\+]?[1-9][\d]{1,14}$')
        .hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  /// Safely truncates text
  static String truncateText(String? text, int maxLength,
      {String suffix = '...'}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$suffix';
  }

  /// Safely calculates percentage
  static double calculatePercentage(dynamic value, dynamic total) {
    return ErrorHandler.handleError(
          () {
            final numValue = (value is String)
                ? double.tryParse(value) ?? 0.0
                : (value as num?)?.toDouble() ?? 0.0;
            final numTotal = (total is String)
                ? double.tryParse(total) ?? 0.0
                : (total as num?)?.toDouble() ?? 0.0;

            if (numTotal == 0) return 0.0;
            return (numValue / numTotal) * 100;
          },
          defaultValue: 0.0,
        ) ??
        0.0;
  }

  /// Safely handles list pagination
  static List<T> paginateList<T>(List<T>? list, int page, int itemsPerPage) {
    if (list == null || list.isEmpty) return [];

    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    return SafeCollectionUtils.safeGetRange(list, startIndex, endIndex);
  }

  /// Helper method to get month name
  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return SafeCollectionUtils.safeElementAt(months, month - 1) ?? 'Jan';
  }

  /// Safely shows snackbar
  static void showSafeSnackBar(BuildContext context, String message,
      {Color? backgroundColor}) {
    ErrorHandler.handleError(
      () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      silent: true,
    );
  }

  /// Safely navigates to a route
  static void safeNavigate(BuildContext context, String routeName,
      {Object? arguments}) {
    ErrorHandler.handleError(
      () {
        if (context.mounted) {
          Navigator.pushNamed(context, routeName, arguments: arguments);
        }
      },
      silent: true,
    );
  }
}
