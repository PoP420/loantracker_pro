// repayment_schedule.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/app_export.dart';
import '../../model.dart';
import '../../model/transaction.dart';
import '../collection_entry/collection_entry.dart';

class RepaymentSchedule extends StatefulWidget {
  final AssignedLoanMdl loan;
  final int collectorId;

  const RepaymentSchedule({super.key, required this.loan, required this.collectorId});

  @override
  State<RepaymentSchedule> createState() => _RepaymentScheduleState();
}

class _RepaymentScheduleState extends State<RepaymentSchedule> {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.102:5000/api/Collector/${widget.collectorId}/assignments/${widget.loan.loan!.loanId}/transactions'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactionsJson = jsonDecode(response.body);
        setState(() {
          _transactions = transactionsJson.map((json) => Transaction.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load transactions: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectTransaction(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionEntry(
          loan: widget.loan,
          collectorId: widget.collectorId,
          selectedTransaction: transaction,
        ),
      ),
    ).then((_) => _fetchTransactions()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Repayment Schedule for ${widget.loan.client?.fullName}'),
        leading: IconButton(
          icon: CustomIconWidget(iconName: 'arrow_back', size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _transactions.isEmpty
          ? const Center(child: Text('No transactions available'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('Due: ${transaction.dueDate.toLocal().toString().split(' ')[0]}'),
              subtitle: Text('Total Due: ₱${transaction.totalDue?.toStringAsFixed(2) ?? '0.00'}'),
              trailing: transaction.isPaid == true
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                onPressed: () => _selectTransaction(transaction),
                child: Text('Pay'),
              ),
            ),
          );
        },
      ),
    );
  }
}