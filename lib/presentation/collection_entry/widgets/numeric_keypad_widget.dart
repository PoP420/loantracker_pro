import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NumericKeypadWidget extends StatelessWidget {
  final Function(String) onKeyTap;

  const NumericKeypadWidget({
    super.key,
    required this.onKeyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Amount',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.5,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
              _buildKeypadButton('.'),
              _buildKeypadButton('0'),
              _buildKeypadButton('⌫', isSpecial: true, action: 'backspace'),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onKeyTap('clear'),
              style: AppTheme.lightTheme.outlinedButtonTheme.style?.copyWith(
                foregroundColor: WidgetStateProperty.all(
                    AppTheme.lightTheme.colorScheme.error),
                side: WidgetStateProperty.all(
                  BorderSide(
                      color: AppTheme.lightTheme.colorScheme.error, width: 1.5),
                ),
              ),
              child: Text(
                'Clear',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value,
      {bool isSpecial = false, String? action}) {
    return Material(
      color: isSpecial
          ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
          : AppTheme.lightTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onKeyTap(action ?? value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSpecial
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline,
              width: 1,
            ),
          ),
          child: Center(
            child: value == '⌫'
                ? CustomIconWidget(
              iconName: 'backspace',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            )
                : Text(
              value,
              style:
              AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSpecial
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
