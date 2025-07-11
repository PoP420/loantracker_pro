import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../services/payment_history_service.dart';

class RecentTransactionsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onViewAll;
  final VoidCallback? onMakeFirstPayment;
  final int? userId; // Add userId to fetch real payment data

  const RecentTransactionsWidget({
    super.key,
    required this.transactions,
    required this.onViewAll,
    this.onMakeFirstPayment,
    this.userId,
  });

  @override
  State<RecentTransactionsWidget> createState() => _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  List<Map<String, dynamic>> _enhancedTransactions = [];
  bool _isLoadingPayments = false;

  @override
  void initState() {
    super.initState();
    _loadEnhancedTransactions();
  }

  Future<void> _loadEnhancedTransactions() async {
    if (widget.userId == null) {
      setState(() {
        _enhancedTransactions = widget.transactions;
      });
      return;
    }

    setState(() {
      _isLoadingPayments = true;
    });

    try {
      print('=== FETCHING REAL PAYMENT STATUS DATA FOR RECENT TRANSACTIONS ===');
      print('User ID: ${widget.userId}');

      final result = await PaymentHistoryService.getRecentPaymentStatusHistory(widget.userId!);

      print('Payment Status History Result: ${result['success']}');

      if (result['success']) {
        final List<dynamic> recentPayments = result['recentPayments'];
        print('Recent Payments Count: ${recentPayments.length}');

        final enhancedTransactions = recentPayments.map((payment) {
          print('Payment Status: ${payment['status']}');

          return {
            "id": payment['id']?.toString() ?? UniqueKey().toString(),
            "date": _formatDateFromPayment(payment['paymentDate']),
            "amount": payment['amount'] ?? 0.0,
            "type": "Payment",
            "status": payment['status'] ?? 'Unknown',
            "method": payment['paymentMethod'] ?? 'GCash',
            "reference": payment['transactionId']?.toString() ?? "N/A",
            "description": _getPaymentDescription(payment),
            "rawStatus": payment['status'], // Keep original for debugging
          };
        }).toList();

        print('Enhanced Transactions: ${enhancedTransactions.length}');
        for (var tx in enhancedTransactions) {
          print('Transaction: ${tx['status']} - ${tx['amount']}');
        }

        setState(() {
          _enhancedTransactions = enhancedTransactions;
        });
      } else {
        print('Failed to fetch payment status history: ${result['message']}');
        setState(() {
          _enhancedTransactions = widget.transactions;
        });
      }
    } catch (e) {
      print('Error loading enhanced transactions: $e');
      setState(() {
        _enhancedTransactions = widget.transactions;
      });
    } finally {
      setState(() {
        _isLoadingPayments = false;
      });
    }
  }

  String _formatDateFromPayment(dynamic paymentDate) {
    if (paymentDate == null) return DateTime.now().toIso8601String().substring(0, 10);

    if (paymentDate is DateTime) {
      return paymentDate.toIso8601String().substring(0, 10);
    }

    if (paymentDate is String) {
      try {
        final date = DateTime.parse(paymentDate);
        return date.toIso8601String().substring(0, 10);
      } catch (e) {
        return paymentDate;
      }
    }

    return DateTime.now().toIso8601String().substring(0, 10);
  }

  String _getPaymentDescription(Map<String, dynamic> payment) {
    final status = payment['status'] as String? ?? 'Unknown';

    switch (status) {
      case 'Pending Review':
        return 'Payment submitted - awaiting approval';
      case 'Paid':
        return 'Payment approved and processed';
      case 'Rejected':
        return 'Payment rejected - please resubmit';
      default:
        return 'Loan Payment';
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
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'pending review':
      case 'pending':
        return AppTheme.warningLight;
      case 'rejected':
      case 'failed':
        return AppTheme.lightTheme.colorScheme.error;
      case 'processing':
        return AppTheme.lightTheme.colorScheme.primary;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'gcash':
        return const Color(0xFF007DFF);
      case 'bank transfer':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'cash':
        return AppTheme.warningLight;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  String _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'gcash':
        return 'account_balance_wallet';
      case 'bank transfer':
        return 'account_balance';
      case 'cash':
        return 'payments';
      default:
        return 'payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPayments) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: widget.onViewAll,
                child: Text(
                  'View All',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    if (_enhancedTransactions.isEmpty) {
      return _EmptyTransactionsWidget(
        onMakeFirstPayment: widget.onMakeFirstPayment,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Recent Transactions',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAll,
              child: Text(
                'View All',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _enhancedTransactions.length > 5 ? 5 : _enhancedTransactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final transaction = _enhancedTransactions[index];
              final status = transaction["status"] as String;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getMethodColor(transaction["method"] as String).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: _getMethodIcon(transaction["method"] as String),
                          color: _getMethodColor(transaction["method"] as String),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Payment',
                            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${transaction["method"]} • ${_formatDate(transaction["date"] as String)}',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatCurrency(transaction["amount"] as double),
                            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: status.toLowerCase() == 'paid'
                                  ? AppTheme.lightTheme.colorScheme.tertiary
                                  : AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyTransactionsWidget extends StatelessWidget {
  final VoidCallback? onMakeFirstPayment;

  const _EmptyTransactionsWidget({
    this.onMakeFirstPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'receipt_long',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions Yet',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here once you make your first payment.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (onMakeFirstPayment != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onMakeFirstPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Make your First Payment',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
