import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../model.dart';
import '../../model/transaction.dart';
import './widgets/transaction_card_widget.dart';
import './widgets/loan_summary_widget.dart';
import './widgets/payment_timeline_widget.dart';

class LoanHistoryScreen extends StatefulWidget {
  final AssignedLoanMdl loan;
  final int collectorId;

  const LoanHistoryScreen({
    super.key,
    required this.loan,
    required this.collectorId,
  });

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterStatus = 'All'; // All, Paid, Pending, Overdue

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = 'http://192.168.1.102:5000/api/Collector/${widget.collectorId}/assignments/${widget.loan.loan?.loanId}/transactions';
      print('Fetching transactions from: $url');
      print('Collector ID: ${widget.collectorId}');
      print('Loan ID: ${widget.loan.loan?.loanId}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Transaction Response status: ${response.statusCode}');
      print('Transaction Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          // Empty response but successful
          setState(() {
            _transactions = [];
          });
          return;
        }

        final List<dynamic> transactionsData = jsonDecode(responseBody);
        setState(() {
          _transactions = transactionsData
              .map((data) => Transaction.fromJson(data))
              .toList();
          // Sort by due date, most recent first
          _transactions.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        });
      } else if (response.statusCode == 404) {
        // No transactions found for this loan
        setState(() {
          _transactions = [];
          _errorMessage = null; // Don't show error for no transactions
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage = 'Access denied. You may not have permission to view this loan\'s transactions.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load transactions: ${response.statusCode}\nResponse: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}\n\nPlease check your internet connection and try again.';
      });
      print('Error fetching transactions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Transaction> get _filteredTransactions {
    switch (_filterStatus) {
      case 'Paid':
        return _transactions.where((t) => t.isPaid).toList();
      case 'Pending':
        return _transactions.where((t) => !t.isPaid && !t.isOverdue).toList();
      case 'Overdue':
        return _transactions.where((t) => t.isOverdue).toList();
      default:
        return _transactions;
    }
  }

  Map<String, dynamic> get _loanSummary {
    final totalAmount = widget.loan.loan?.total ?? 0.0;
    final paidAmount = _transactions
        .where((t) => t.isPaid)
        .fold(0.0, (sum, t) => sum + t.totalDue);
    final pendingAmount = _transactions
        .where((t) => !t.isPaid)
        .fold(0.0, (sum, t) => sum + t.totalDue);
    final overdueAmount = _transactions
        .where((t) => t.isOverdue)
        .fold(0.0, (sum, t) => sum + t.totalDue);

    return {
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'overdueAmount': overdueAmount,
      'remainingBalance': pendingAmount,
      'paymentProgress': totalAmount > 0 ? (paidAmount / totalAmount) : 0.0,
      'totalTransactions': _transactions.length,
      'paidTransactions': _transactions.where((t) => t.isPaid).length,
      'pendingTransactions': _transactions.where((t) => !t.isPaid).length,
    };
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.bottomSheetTheme.backgroundColor,
      shape: AppTheme.lightTheme.bottomSheetTheme.shape,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Filter Transactions',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            ...['All', 'Paid', 'Pending', 'Overdue'].map((status) => ListTile(
              leading: Radio<String>(
                value: status,
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              title: Text(status),
              subtitle: Text(
                '${_getTransactionCountForStatus(status)} transactions',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              onTap: () {
                setState(() {
                  _filterStatus = status;
                });
                Navigator.pop(context);
              },
            )),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  int _getTransactionCountForStatus(String status) {
    switch (status) {
      case 'Paid':
        return _transactions.where((t) => t.isPaid).length;
      case 'Pending':
        return _transactions.where((t) => !t.isPaid && !t.isOverdue).length;
      case 'Overdue':
        return _transactions.where((t) => t.isOverdue).length;
      default:
        return _transactions.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan History',
              style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
            ),
            Text(
              widget.loan.client?.fullName ?? 'Unknown Client',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.appBarTheme.foregroundColor!
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _fetchTransactions,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
              size: 24,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Loan Summary
          LoanSummaryWidget(
            loan: widget.loan,
            summary: _loanSummary,
          ),

          // Filter Status Indicator
          if (_filterStatus != 'All')
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'filter_list',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing $_filterStatus transactions (${_filteredTransactions.length})',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterStatus = 'All';
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Transactions Tab
                _buildTransactionsTab(),
                // Timeline Tab
                _buildTimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'error_outline',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Transactions',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchTransactions,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Show debug info
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Debug Information'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Collector ID: ${widget.collectorId}'),
                            Text('Loan ID: ${widget.loan.loan?.loanId}'),
                            Text('Client: ${widget.loan.client?.fullName}'),
                            Text('API URL: http://192.168.1.33:5000/api/Collector/${widget.collectorId}/assignments/${widget.loan.loan?.loanId}/transactions'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Show Debug Info'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'receipt_long',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _filterStatus == 'All'
                    ? 'No Transactions Found'
                    : 'No $_filterStatus Transactions',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _filterStatus == 'All'
                    ? 'This loan has no transaction history yet, or transactions may not be available in the system.'
                    : 'No transactions match the current filter.',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchTransactions,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          return TransactionCardWidget(
            transaction: transaction,
            onTap: () => _showTransactionDetails(transaction),
          );
        },
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Text(
          'No transaction timeline available',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
      );
    }

    return PaymentTimelineWidget(
      transactions: _transactions,
      loan: widget.loan,
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.bottomSheetTheme.backgroundColor,
      shape: AppTheme.lightTheme.bottomSheetTheme.shape,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Container(
                width: 12.w,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Transaction Details',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      _buildDetailRow('Transaction ID', '#${transaction.id}'),
                      _buildDetailRow('Status', transaction.statusText),
                      _buildDetailRow('Due Date',
                          '${transaction.dueDate.day}/${transaction.dueDate.month}/${transaction.dueDate.year}'),
                      _buildDetailRow('Principal Due',
                          '₱${transaction.principalDue.toStringAsFixed(2)}'),
                      _buildDetailRow('Interest Due',
                          '₱${transaction.interestDue.toStringAsFixed(2)}'),
                      if (transaction.hasPenalties)
                        _buildDetailRow('Penalties',
                            '₱${transaction.penaltiesDue.toStringAsFixed(2)}'),
                      if (transaction.hasServiceFees)
                        _buildDetailRow('Service Fees',
                            '₱${transaction.serviceFeesDue.toStringAsFixed(2)}'),
                      _buildDetailRow('Total Due',
                          '₱${transaction.totalDue.toStringAsFixed(2)}',
                          isHighlighted: true),
                      if (transaction.remarks?.isNotEmpty == true)
                        _buildDetailRow('Remarks', transaction.remarks!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
            : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted
            ? Border.all(color: AppTheme.lightTheme.colorScheme.primary)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: isHighlighted
                    ? AppTheme.lightTheme.colorScheme.primary
                    : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
