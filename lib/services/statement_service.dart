import 'dart:convert';
import 'package:http/http.dart' as http;

class StatementService {
  static const String baseUrl = 'https://192.168.1.102:5000/api';
  
  // Get account information for a user
  static Future<List<Map<String, dynamic>>> getAccountInfo(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Statement/account-info/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load account info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching account info: $e');
    }
  }
  
  // Get account summary for a specific period
  static Future<Map<String, dynamic>> getAccountSummary({
    required int userId,
    required int loanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'loanId': loanId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/account-summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load account summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching account summary: $e');
    }
  }
  
  // Get transaction timeline with filters
  static Future<List<Map<String, dynamic>>> getTransactions({
    required int userId,
    required int loanId,
    required DateTime startDate,
    required DateTime endDate,
    String transactionType = 'all',
    double minAmount = 0.0,
    double maxAmount = 999999.0,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'loanId': loanId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'transactionType': transactionType,
        'minAmount': minAmount,
        'maxAmount': maxAmount,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }
  
  // Get complete statement data
  static Future<Map<String, dynamic>> getFullStatement({
    required int userId,
    required int loanId,
    required DateTime startDate,
    required DateTime endDate,
    String transactionType = 'all',
    double minAmount = 0.0,
    double maxAmount = 999999.0,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'loanId': loanId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'transactionType': transactionType,
        'minAmount': minAmount,
        'maxAmount': maxAmount,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/full-statement'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load full statement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching full statement: $e');
    }
  }
  
  // Export statement as PDF
  static Future<List<int>> exportStatementPdf({
    required int userId,
    required int loanId,
    required DateTime startDate,
    required DateTime endDate,
    String transactionType = 'all',
    double minAmount = 0.0,
    double maxAmount = 999999.0,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'loanId': loanId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'transactionType': transactionType,
        'minAmount': minAmount,
        'maxAmount': maxAmount,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/export-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to export PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting PDF: $e');
    }
  }
}
