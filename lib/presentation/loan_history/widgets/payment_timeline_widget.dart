import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../../model.dart';
import '../../../../model/transaction.dart';

class PaymentTimelineWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final AssignedLoanMdl loan;

  const PaymentTimelineWidget({
    super.key,
    required this.transactions,
    required this.loan,
  });

  @override
  Widget build(BuildContext context) {
    // Sort transactions by due date for timeline
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: sortedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = sortedTransactions[index];
        final isLast = index == sortedTransactions.length - 1;
        
        return _buildTimelineItem(transaction, isLast);
      },
    );
  }

  Widget _buildTimelineItem(Transaction transaction, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: transaction.statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  width: 3,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: transaction.isPaid ? 'check' : 'schedule',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 10,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
              ),
          ],
        ),
        
        SizedBox(width: 4.w),
        
        // Transaction content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: transaction.statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${transaction.dueDate.day}/${transaction.dueDate.month}/${transaction.dueDate.year}',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: transaction.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.statusText,
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: transaction.statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '₱${transaction.totalDue.toStringAsFixed(2)}',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: transaction.statusColor,
                  ),
                ),
                
                if (transaction.remarks?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    transaction.remarks!,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
