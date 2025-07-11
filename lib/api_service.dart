import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model/transaction.dart';

class ApiService {
  final String _baseUrl = "http://192.168.1.102:5000/api";

  Future<List<Transaction>> getLoanTransactions(
      int collectorId, int loanId) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/Collector/$collectorId/assignments/$loanId/transactions'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> transactionsJson = jsonDecode(response.body);
      return transactionsJson
          .map((json) => Transaction.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<void> updatePayment(int userId, int loanId, int loanTransactionId,
      double amount, String imagePath) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/Collector/payments'));
    request.fields['UserID'] = userId.toString();
    request.fields['LoanID'] = loanId.toString();
    request.fields['LoanTransactionID'] = loanTransactionId.toString();
    request.fields['Amount'] = amount.toString();
    request.files
        .add(await http.MultipartFile.fromPath('paymentProofImage', imagePath));

    var response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to update payment');
    }
  }
}
