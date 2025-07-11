import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model.dart';

class LoanService {
  final String _baseUrl = "http://192.168.1.102:5000/api";

  Future<List<LoanMdl>> fetchLoanData(int userId) async {
    try {
      print('=== LOAN SERVICE: Fetching loan data for user $userId ===');

      final uri = Uri.parse('$_baseUrl/Loans/client/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('Loan Service Response Status: ${response.statusCode}');
      print('Loan Service Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle the new comprehensive API response structure
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final List<dynamic> loansData = responseData['data'] ?? [];

          return loansData.map((loanData) {
            return LoanMdl(
              loanId: loanData['loanId'],
              userId: loanData['userId'],
              loanTypeID: loanData['loanTypeID'],
              amount: (loanData['loanAmount'] as num?)?.toDouble(),
              interest: (loanData['interest'] as num?)?.toDouble(),
              total: (loanData['total'] as num?)?.toDouble(),
              loanTerm: loanData['loanTerm'],
              status: loanData['status'],
            );
          }).toList();
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        throw Exception('Failed to load loan data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchLoanData: $e');
      throw Exception('Error fetching loan data: $e');
    }
  }

  Future<List<LoanTrxnMdl>> fetchLoanTransactions(int loanId) async {
    try {
      print('=== LOAN SERVICE: Fetching transactions for loan $loanId ===');

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
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == '[]') {
          return [];
        }

        final List<dynamic> transactionsJson = jsonDecode(responseBody);
        return transactionsJson.map((json) => LoanTrxnMdl.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchLoanTransactions: $e');
      throw Exception('Error fetching transactions: $e');
    }
  }

  Future<List<TrxnHistory>> fetchPaymentHistory(int loanId) async {
    try {
      print('=== LOAN SERVICE: Fetching payment history for loan $loanId ===');

      final uri = Uri.parse('$_baseUrl/Loans/$loanId/payments');
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
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == '[]') {
          return [];
        }

        final List<dynamic> paymentsJson = jsonDecode(responseBody);
        return paymentsJson.map((json) => TrxnHistory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load payment history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchPaymentHistory: $e');
      throw Exception('Error fetching payment history: $e');
    }
  }

  // New method to fetch comprehensive loan data using the enhanced API
  Future<ComprehensiveLoanData?> fetchComprehensiveLoanData(int userId) async {
    try {
      print('=== LOAN SERVICE: Fetching comprehensive loan data for user $userId ===');

      final uri = Uri.parse('$_baseUrl/Loans/client/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('Comprehensive Data Response Status: ${response.statusCode}');
      print('Comprehensive Data Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final List<dynamic> loansData = responseData['data'] ?? [];

          if (loansData.isNotEmpty) {
            final loanData = loansData.first as Map<String, dynamic>;
            return ComprehensiveLoanData.fromJson(loanData);
          }
        }
        return null;
      } else {
        throw Exception('Failed to load comprehensive loan data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchComprehensiveLoanData: $e');
      throw Exception('Error fetching comprehensive loan data: $e');
    }
  }
}
