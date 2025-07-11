import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentHistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;
  final Function(String) onQuickAction;

  const PaymentHistoryCardWidget({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onQuickAction,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'pending review':
      case 'pending':
        return AppTheme.warningLight;
      case 'scheduled':
        return Colors.blue;
      case 'overdue':
        return AppTheme.lightTheme.colorScheme.error;
      case 'rejected':
      case 'failed':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'gcash':
        return Icons.account_balance_wallet;
      case 'bank transfer':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'paymaya':
        return Icons.credit_card;
      case 'pending review':
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = transaction["paymentDate"] as DateTime;
    final amount = (transaction["amount"] as num?)?.toDouble() ?? 0.0;
    final status = transaction["status"] as String? ?? 'Unknown';
    final paymentMethod = transaction["paymentMethod"] as String? ?? 'Unknown';
    final referenceNumber = transaction["referenceNumber"] as String? ?? 'N/A';
    final description = transaction["description"] as String? ?? 'Payment';
    final receiptUrl = transaction["receiptUrl"] as String?;
    final isPending = transaction["isPending"] == true;
    final isOverdue = transaction["isOverdue"] == true;
    final isScheduled = transaction["isScheduled"] == true;
    final isActualPayment = transaction["isActualPayment"] == true;

    return Dismissible(
      key: Key(transaction["id"]?.toString() ?? UniqueKey().toString()),
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _showQuickActionsDialog(context);
        } else {
          if (status.toLowerCase() == 'failed' || isOverdue) {
            onQuickAction('Dispute');
          }
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showQuickActionsDialog(context);
        } else if (direction == DismissDirection.endToStart &&
            (status.toLowerCase() == 'failed' || isOverdue)) {
          onQuickAction('Dispute');
        }
        return false; // Don't actually dismiss the card
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        child: Card(
          elevation: (isPending || isOverdue || isScheduled) ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: (isPending || isOverdue || isScheduled)
                ? BorderSide(
              color: _getStatusColor(status).withValues(alpha: 0.3),
              width: isOverdue ? 2 : 1,
            )
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: isOverdue
                  ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.05),
                    AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.02),
                  ],
                ),
              )
                  : isScheduled
                  ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withValues(alpha: 0.05),
                    Colors.blue.withValues(alpha: 0.02),
                  ],
                ),
              )
                  : null,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '₱${amount.toStringAsFixed(2)}',
                                    style: AppTheme.lightTheme.textTheme.headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isOverdue
                                          ? AppTheme.lightTheme.colorScheme.error
                                          : (isPending || isScheduled)
                                          ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                                          : AppTheme.lightTheme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (isPending || isOverdue || isScheduled) ...[
                                    SizedBox(width: 2.w),
                                    CustomIconWidget(
                                      iconName: isOverdue ? 'warning' : isScheduled ? 'schedule' : 'schedule',
                                      size: 4.w,
                                      color: _getStatusColor(status),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                description,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: (isOverdue || isScheduled)
                                ? Border.all(
                              color: _getStatusColor(status).withValues(alpha: 0.3),
                              width: 1,
                            )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOverdue) ...[
                                CustomIconWidget(
                                  iconName: 'warning',
                                  size: 3.w,
                                  color: _getStatusColor(status),
                                ),
                                SizedBox(width: 1.w),
                              ] else if (isScheduled) ...[
                                CustomIconWidget(
                                  iconName: 'schedule',
                                  size: 3.w,
                                  color: _getStatusColor(status),
                                ),
                                SizedBox(width: 1.w),
                              ],
                              Text(
                                status,
                                style: AppTheme.lightTheme.textTheme.labelMedium
                                    ?.copyWith(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: _getPaymentMethodIcon(paymentMethod)
                              .codePoint
                              .toString(),
                          size: 4.w,
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          (isPending || isOverdue || isScheduled) ? 'Due Date' : paymentMethod,
                          style:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color:
                            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? AppTheme.lightTheme.colorScheme.error
                                : isScheduled
                                ? Colors.blue
                                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            fontWeight: (isOverdue || isScheduled)
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Text(
                          'Ref: $referenceNumber',
                          style:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color:
                            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Spacer(),
                        if (receiptUrl != null)
                          CustomIconWidget(
                            iconName: 'receipt',
                            size: 4.w,
                            color: AppTheme.lightTheme.primaryColor,
                          ),
                        // Show Pay Now button for pending, overdue, and scheduled transactions
                        if ((isOverdue || isScheduled) && status.toLowerCase() != 'paid')
                          Container(
                            margin: EdgeInsets.only(left: 2.w),
                            child: ElevatedButton(
                              onPressed: () => onQuickAction('Pay Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOverdue
                                    ? AppTheme.lightTheme.colorScheme.error
                                    : isScheduled
                                    ? Colors.blue
                                    : AppTheme.lightTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: (isOverdue || isScheduled) ? 2 : 1,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isOverdue) ...[
                                    CustomIconWidget(
                                      iconName: 'priority_high',
                                      size: 3.w,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 1.w),
                                  ] else if (isScheduled) ...[
                                    CustomIconWidget(
                                      iconName: 'schedule',
                                      size: 3.w,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 1.w),
                                  ],
                                  Text(
                                    isOverdue ? 'Pay Now!' : isScheduled ? 'Pay Early' : 'Pay Now',
                                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Add urgency indicator for overdue payments
                    if (isOverdue) ...[
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'warning',
                              size: 4.w,
                              color: AppTheme.lightTheme.colorScheme.error,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                'Payment is overdue. Please pay immediately to avoid additional penalties.',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Add info indicator for scheduled payments
                    if (isScheduled) ...[
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'schedule',
                              size: 4.w,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                'Scheduled payment. You can pay early to avoid any delays.',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeftSwipe) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: isLeftSwipe
            ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: isLeftSwipe ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: isLeftSwipe ? 'more_horiz' : 'report_problem',
                size: 8.w,
                color: isLeftSwipe
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.error,
              ),
              SizedBox(height: 1.h),
              Text(
                isLeftSwipe ? 'Actions' : 'Dispute',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: isLeftSwipe
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionsDialog(BuildContext context) {
    final isPending = transaction["isPending"] == true;
    final status = transaction["status"] as String? ?? '';
    final isOverdue = transaction["isOverdue"] == true;
    final isScheduled = transaction["isScheduled"] == true;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Quick Actions',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            // Pay Now action for pending, overdue, and scheduled
            if ((isPending || isOverdue || isScheduled) && status.toLowerCase() != 'paid')
              _buildActionTile(
                context,
                isOverdue ? 'Pay Now (Overdue!)' : isScheduled ? 'Pay Early' : 'Pay Now',
                'payment',
                    () => onQuickAction('Pay Now'),
                isUrgent: isOverdue,
              ),
            if (!isPending && !isOverdue && !isScheduled) ...[
              _buildActionTile(
                context,
                'View Receipt',
                'receipt',
                    () => onQuickAction('View Receipt'),
              ),
              _buildActionTile(
                context,
                'Download PDF',
                'download',
                    () => onQuickAction('Download PDF'),
              ),
            ],
            _buildActionTile(
              context,
              'Share Details',
              'share',
                  () => onQuickAction('Share Details'),
            ),
            if (isOverdue)
              _buildActionTile(
                context,
                'Contact Support',
                'support',
                    () => onQuickAction('Contact Support'),
              ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
      BuildContext context,
      String title,
      String icon,
      VoidCallback onTap, {
        bool isUrgent = false,
      }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        size: 6.w,
        color: isUrgent
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.primaryColor,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: isUrgent
              ? AppTheme.lightTheme.colorScheme.error
              : null,
          fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: isUrgent
          ? AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.05)
          : null,
    );
  }
}
