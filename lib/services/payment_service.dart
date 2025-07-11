import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model.dart';

class PaymentService {
  static const String _baseUrl = "http://192.168.1.102:5000/api";

  static Future<Map<String, dynamic>> processPayment({
    required int loanId,
    required int userId,
    required int loanTransactionId,
    required double amount,
    DateTime? paymentDate,
    File? receiptImage,
  }) async {
    try {
      print('=== SUBMITTING PAYMENT FOR APPROVAL ===');
      print('Loan ID: $loanId');
      print('User ID: $userId');
      print('Transaction ID: $loanTransactionId');
      print('Amount: $amount');

      final uri = Uri.parse('$_baseUrl/Loans/payments');

      var request = http.MultipartRequest('POST', uri);

      // FIX: Round amount to avoid precision issues
      final roundedAmount = double.parse(amount.toStringAsFixed(2));

      request.fields['LoanID'] = loanId.toString();
      request.fields['UserID'] = userId.toString();
      request.fields['LoanTransactionID'] = loanTransactionId.toString();
      request.fields['Amount'] = roundedAmount.toString(); // Use rounded amount

      if (paymentDate != null) {
        request.fields['PaymentDate'] = paymentDate.toIso8601String();
      }

      if (receiptImage != null) {
        var imageStream = http.ByteStream(receiptImage.openRead());
        var imageLength = await receiptImage.length();
        var multipartFile = http.MultipartFile(
          'paymentProofImage',
          imageStream,
          imageLength,
          filename: 'payment_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      }

      print('Sending payment submission to: $uri');
      print('Rounded amount: $roundedAmount');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Payment Response Status: ${response.statusCode}');
      print('Payment Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Payment submitted successfully and is pending approval.',
          'paymentId': responseData['paymentId'],
          'status': responseData['status'] ?? 'Pending',
          'submittedAmount': responseData['submittedAmount'],
          'transactionId': responseData['transactionId'],
          'estimatedApprovalTime': responseData['estimatedApprovalTime'] ?? '24-48 hours',
          'hasReceipt': responseData['hasReceipt'] ?? false,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['Message'] ?? 'Payment submission failed',
          'error': errorData,
        };
      }
    } catch (e) {
      print('Payment Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> submitPaymentForApproval({
    required int loanId,
    required int userId,
    required int loanTransactionId,
    required double amount,
    DateTime? paymentDate,
    File? receiptImage,
  }) async {
    return processPayment(
      loanId: loanId,
      userId: userId,
      loanTransactionId: loanTransactionId,
      amount: amount,
      paymentDate: paymentDate,
      receiptImage: receiptImage,
    );
  }

  static Future<Map<String, dynamic>> getLoanTransactions(int loanId) async {
    try {
      print('=== FETCHING LOAN TRANSACTIONS ===');
      print('Loan ID: $loanId');

      final uri = Uri.parse('$_baseUrl/Loans/$loanId/transactions');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('Transactions Response Status: ${response.statusCode}');
      print('Transactions Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> transactionsData = jsonDecode(response.body);

        final transactions = transactionsData.map((t) {
          return LoanTrxnMdl.fromJson(t as Map<String, dynamic>);
        }).toList();

        return {
          'success': true,
          'transactions': transactions,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['Message'] ?? 'Failed to fetch transactions',
        };
      }
    } catch (e) {
      print('Transactions Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
