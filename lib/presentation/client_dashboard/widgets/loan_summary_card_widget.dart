// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_export.dart';
import '../../../model.dart';
import '../../../loan_service.dart';

class LoanSummaryCardWidget extends StatefulWidget {
  final int loanId;
  final int userId;
  final String loanStatus;
  final double nextPaymentAmount;
  final String nextPaymentDate;
  final double outstandingBalance;

  const LoanSummaryCardWidget({
    super.key,
    required this.loanId,
    required this.userId,
    required this.loanStatus,
    required this.nextPaymentAmount,
    required this.nextPaymentDate,
    required this.outstandingBalance,
  });

  @override
  State<LoanSummaryCardWidget> createState() => _LoanSummaryCardWidgetState();
}

class _LoanSummaryCardWidgetState extends State<LoanSummaryCardWidget> {
  bool isLoading = false; // Changed to false since data is passed from parent
  LoanMdl? loan;
  List<LoanTrxnMdl> transactions = [];
  double outstandingBalance = 0;
  LoanTrxnMdl? nextPayment;
  String loanStatus = 'current';

  @override
  void initState() {
    super.initState();
    // Use the data passed from parent instead of fetching again
    _initializeFromProps();
  }

  void _initializeFromProps() {
    try {
      // Use the data passed from parent
      outstandingBalance = widget.outstandingBalance;
      loanStatus = _determineLoanStatus();

      // Create a mock next payment from the passed data
      if (widget.nextPaymentAmount > 0 && widget.nextPaymentDate != "N/A") {
        nextPayment = LoanTrxnMdl(
          totalDue: widget.nextPaymentAmount,
          dueDate: DateTime.tryParse(widget.nextPaymentDate),
          isPaid: false,
          loanID: widget.loanId,
        );
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error initializing loan summary: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _determineLoanStatus() {
    // Determine status based on next payment date
    if (widget.nextPaymentDate == "N/A" || widget.nextPaymentAmount <= 0) {
      return 'current';
    }

    try {
      final nextDueDate = DateTime.tryParse(widget.nextPaymentDate);
      if (nextDueDate == null) return 'current';

      final now = DateTime.now();
      final daysUntilPayment = nextDueDate.difference(now).inDays;

      if (daysUntilPayment < 0) return 'overdue';
      if (daysUntilPayment <= 7) return 'due_soon';
      return 'current';
    } catch (e) {
      return 'current';
    }
  }

  // Remove the old _loadLoanData method since we're using parent data

  Color _getStatusColor() {
    switch (loanStatus.toLowerCase()) {
      case 'overdue':
        return AppTheme.lightTheme.colorScheme.error;
      case 'due_soon':
        return AppTheme.warningLight;
      case 'current':
      default:
        return AppTheme.lightTheme.colorScheme.tertiary;
    }
  }

  String _getStatusText() {
    switch (loanStatus.toLowerCase()) {
      case 'overdue':
        return 'Overdue';
      case 'due_soon':
        return 'Due Soon';
      case 'current':
      default:
        return 'Current';
    }
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  int _getDaysUntilPayment() {
    if (widget.nextPaymentDate == "N/A") return 0;

    try {
      final paymentDate = DateTime.parse(widget.nextPaymentDate);
      final now = DateTime.now();
      return paymentDate.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    final daysUntilPayment = _getDaysUntilPayment();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Outstanding Balance',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor().withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusText(),
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(outstandingBalance),
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.onPrimary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Payment',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(widget.nextPaymentAmount),
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Due Date',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.nextPaymentDate != "N/A"
                              ? _formatDate(widget.nextPaymentDate)
                              : 'N/A',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.nextPaymentDate != "N/A" && widget.nextPaymentAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: daysUntilPayment <= 3
                          ? AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.2)
                          : daysUntilPayment <= 7
                          ? AppTheme.warningLight.withValues(alpha: 0.2)
                          : AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: daysUntilPayment <= 0 ? 'warning' : 'schedule',
                          color: daysUntilPayment <= 3
                              ? AppTheme.lightTheme.colorScheme.error
                              : daysUntilPayment <= 7
                              ? AppTheme.warningLight
                              : AppTheme.lightTheme.colorScheme.tertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          daysUntilPayment <= 0
                              ? 'Payment overdue'
                              : daysUntilPayment == 1
                              ? '1 day remaining'
                              : '$daysUntilPayment days remaining',
                          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                            color: daysUntilPayment <= 3
                                ? AppTheme.lightTheme.colorScheme.error
                                : daysUntilPayment <= 7
                                ? AppTheme.warningLight
                                : AppTheme.lightTheme.colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}