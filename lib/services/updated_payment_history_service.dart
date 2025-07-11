import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model.dart';

class PaymentHistoryService {
  static const String _baseUrl = "http://192.168.1.102:5000/api";

  static Future<Map<String, dynamic>> getPaymentHistory(int userId) async {
    try {
      print('=== FETCHING PAYMENT HISTORY ===');
      print('User ID: $userId');

      final uri = Uri.parse('$_baseUrl/Loans/user/$userId/payment-history');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('Payment History Response Status: ${response.statusCode}');
      print('Payment History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);

        final paymentHistory = historyData.map((payment) {
          String displayStatus = _mapPaymentStatus(payment['status'] as String?);
          bool isActualPayment = payment['isActualPayment'] == true;

          return {
            'id': payment['id'],
            'loanId': payment['loanId'],
            'amount': (payment['amount'] as num?)?.toDouble() ?? 0.0,
            'paymentDate': payment['paymentDate'] != null
                ? DateTime.tryParse(payment['paymentDate']) ?? DateTime.now()
                : DateTime.now(),
            'status': displayStatus,
            'rawStatus': payment['status'],
            'transactionId': payment['transactionId'],
            'receiptUrl': payment['receiptUrl'],
            'approvalDate': payment['approvalDate'] != null
                ? DateTime.tryParse(payment['approvalDate'])
                : null,
            'rejectionReason': payment['rejectionReason'],
            'notes': payment['notes'],
            'submittedDate': payment['submittedDate'] != null
                ? DateTime.tryParse(payment['submittedDate'])
                : null,
            'approvedBy': payment['approvedBy'],
            'remarks': payment['remarks'],
            'isActualPayment': isActualPayment,
            // Additional fields for overdue payments
            'principalDue': payment['principalDue'],
            'interestDue': payment['interestDue'],
            'penaltiesDue': payment['penaltiesDue'],
            'serviceFeesDue': payment['serviceFeesDue'],
            'dueDate': payment['dueDate'] != null
                ? DateTime.tryParse(payment['dueDate'])
                : null,
            // UI flags
            'isPending': displayStatus.toLowerCase().contains('pending'),
            'isOverdue': displayStatus.toLowerCase() == 'overdue',
          };
        }).toList();

        paymentHistory.sort((a, b) =>
            (b['paymentDate'] as DateTime).compareTo(a['paymentDate'] as DateTime));

        return {
          'success': true,
          'paymentHistory': paymentHistory,
        };
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['Message'] ?? 'No payment history found for this user',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['Message'] ?? 'Failed to fetch payment history',
        };
      }
    } catch (e) {
      print('Payment History Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static String _mapPaymentStatus(String? status) {
    if (status == null) return 'Unknown';

    switch (status.toLowerCase()) {
      case 'pending':
      case 'submitted':
      case 'under_review':
        return 'Pending Review';
      case 'approved':
      case 'paid':
      case 'completed':
        return 'Paid';
      case 'rejected':
      case 'declined':
      case 'failed':
        return 'Rejected';
      case 'processing':
        return 'Processing';
      case 'cancelled':
        return 'Cancelled';
      case 'overdue':
        return 'Overdue';
      default:
        return status.split('_').map((word) =>
        word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
    }
  }

  static Future<Map<String, dynamic>> getPaymentStatistics(int userId) async {
    try {
      final result = await getPaymentHistory(userId);

      if (result['success']) {
        final List<dynamic> payments = result['paymentHistory'];

        double totalPaid = 0.0;
        int pendingCount = 0;
        int paidCount = 0;
        int rejectedCount = 0;
        int overdueCount = 0;

        for (var payment in payments) {
          final status = payment['status'] as String;
          final amount = payment['amount'] as double;
          final isActualPayment = payment['isActualPayment'] == true;

          switch (status) {
            case 'Paid':
              if (isActualPayment) {
                totalPaid += amount;
                paidCount++;
              }
              break;
            case 'Pending Review':
              if (isActualPayment) {
                pendingCount++;
              }
              break;
            case 'Rejected':
              if (isActualPayment) {
                rejectedCount++;
              }
              break;
            case 'Overdue':
              if (!isActualPayment) {
                overdueCount++;
              }
              break;
          }
        }

        return {
          'success': true,
          'statistics': {
            'totalPaid': totalPaid,
            'totalPayments': payments.where((p) => p['isActualPayment'] == true).length,
            'pendingCount': pendingCount,
            'paidCount': paidCount,
            'rejectedCount': rejectedCount,
            'overdueCount': overdueCount,
          },
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to calculate payment statistics: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getRecentPayments(int userId) async {
    try {
      final result = await getPaymentHistory(userId);

      if (result['success']) {
        final List<dynamic> allPayments = result['paymentHistory'];
        final recentPayments = allPayments.take(5).toList();

        return {
          'success': true,
          'recentPayments': recentPayments,
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch recent payments: ${e.toString()}',
      };
    }
  }
}
