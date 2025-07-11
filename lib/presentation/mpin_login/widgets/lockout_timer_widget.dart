import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LockoutTimerWidget extends StatelessWidget {
  final int timeRemaining;
  final VoidCallback onResetViaSms;

  const LockoutTimerWidget({
    super.key,
    required this.timeRemaining,
    required this.onResetViaSms,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Warning Icon
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color:
                  AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'lock_clock',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 8.w,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Title
          Text(
            'Account Temporarily Locked',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 2.h),

          // Description
          Text(
            'Too many incorrect attempts. Please wait or reset your PIN.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 4.h),

          // Timer Display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'timer',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  _formatTime(timeRemaining),
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.error,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Reset via SMS Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onResetViaSms,
              icon: CustomIconWidget(
                iconName: 'sms',
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 20,
              ),
              label: const Text('Reset PIN via SMS'),
              style: AppTheme.lightTheme.elevatedButtonTheme.style?.copyWith(
                backgroundColor: WidgetStateProperty.all(
                  AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
