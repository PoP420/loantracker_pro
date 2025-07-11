import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class GCashPaymentWidget extends StatelessWidget {
  final VoidCallback onQrScanPressed;
  final bool isEnabled;

  const GCashPaymentWidget({
    super.key,
    required this.onQrScanPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007DFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'account_balance_wallet',
                  color: const Color(0xFF007DFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GCash Payment',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Scan QR code to pay instantly',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Recommended',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Pay with QR Code Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isEnabled ? onQrScanPressed : null,
              icon: CustomIconWidget(
                iconName: 'qr_code_scanner',
                color: isEnabled
                    ? AppTheme.lightTheme.colorScheme.onPrimary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.38),
                size: 20,
              ),
              label: Text(
                'Pay with QR Code',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: isEnabled
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                      : AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.38),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled
                    ? const Color(0xFF007DFF)
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.12),
                foregroundColor: isEnabled
                    ? Colors.white
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isEnabled ? 2 : 0,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Features List
          _buildFeatureItem(
            context,
            'qr_code',
            'Instant QR Code Scanning',
            'Point your camera at the merchant\'s QR code',
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            context,
            'flash_on',
            'Built-in Flashlight',
            'Scan QR codes even in low light conditions',
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            context,
            'security',
            'Secure Transaction',
            'End-to-end encrypted payment processing',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, String iconName, String title, String description) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
