import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onMakePayment;
  final VoidCallback onViewSchedule;
  final VoidCallback onUploadReceipt;
  final VoidCallback onContactSupport;
  final VoidCallback onViewStatement;

  const QuickActionsWidget({
    super.key,
    required this.onMakePayment,
    required this.onViewSchedule,
    required this.onUploadReceipt,
    required this.onContactSupport,
    required this.onViewStatement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // **FIX: Increase height slightly to prevent overflow**
        SizedBox(
          height: 130, // Increased from 120 to 130
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _QuickActionCard(
                icon: 'payment',
                title: 'Make Payment',
                subtitle: 'Pay your loan',
                color: AppTheme.lightTheme.colorScheme.primary,
                onTap: onMakePayment,
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: 'schedule',
                title: 'View Schedule',
                subtitle: 'Payment timeline',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                onTap: onViewSchedule,
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: 'upload_file',
                title: 'Upload Receipt',
                subtitle: 'Submit payment proof',
                color: AppTheme.warningLight,
                onTap: onUploadReceipt,
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: 'support_agent',
                title: 'Contact Support',
                subtitle: 'Get help',
                color: AppTheme.lightTheme.colorScheme.secondary,
                onTap: onContactSupport,
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: 'receipt_long',
                title: 'View Statement',
                subtitle: 'Account Statement',
                color: AppTheme.lightTheme.colorScheme.surfaceTint,
                onTap: onViewStatement,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
            AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
              AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // **FIX: Prevent expansion**
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8), // **FIX: Reduced from 12 to 8**
            // **FIX: Use Flexible to prevent overflow**
            Flexible(
              child: Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // **FIX: Use Flexible to prevent overflow**
            Flexible(
              child: Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
