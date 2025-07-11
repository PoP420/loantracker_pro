import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class UploadButtonWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const UploadButtonWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isPrimary = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: isPrimary ? _buildPrimaryButton() : _buildSecondaryButton(),
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
        elevation: 2,
        shadowColor: AppTheme.lightTheme.colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.lightTheme.colorScheme.primary,
        side: BorderSide(
          color: AppTheme.lightTheme.colorScheme.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary
                ? AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.2)
                : AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomIconWidget(
            iconName: icon,
            color: isPrimary
                ? AppTheme.lightTheme.colorScheme.onPrimary
                : AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                      : AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: isPrimary
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                          .withValues(alpha: 0.8)
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        CustomIconWidget(
          iconName: 'arrow_forward_ios',
          color: isPrimary
              ? AppTheme.lightTheme.colorScheme.onPrimary.withValues(alpha: 0.6)
              : AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6),
          size: 16,
        ),
      ],
    );
  }
}
