import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SecurityInfoWidget extends StatelessWidget {
  const SecurityInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info_outline',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Security Requirements',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSecurityItem(
            'No sequential numbers (123456)',
            'block',
          ),
          SizedBox(height: 1.h),
          _buildSecurityItem(
            'No repeated digits (111111)',
            'block',
          ),
          SizedBox(height: 1.h),
          _buildSecurityItem(
            'Avoid common patterns',
            'block',
          ),
          SizedBox(height: 1.h),
          _buildSecurityItem(
            'Stored securely on your device',
            'verified_user',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String text, String iconName) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 16,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            text,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
