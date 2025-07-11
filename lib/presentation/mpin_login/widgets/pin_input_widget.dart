import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PinInputWidget extends StatelessWidget {
  final List<String> pinDigits;
  final bool isLoading;
  final int pinLength; // Added pinLength parameter

  const PinInputWidget({
    super.key,
    required this.pinDigits,
    required this.isLoading,
    this.pinLength = 6, // Default to 6, will be overridden by parent
  });

  @override
  Widget build(BuildContext context) {
    if (pinDigits.length != pinLength) {
      // Developer error: pinDigits list must match pinLength
      return Text('Error: pinDigits length mismatch.',
          style: TextStyle(color: Colors.red));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(pinLength, (index) {
        // Use pinLength
        return _buildPinField(index);
      }),
    );
  }

  Widget _buildPinField(int index) {
    final bool hasValue = pinDigits[index].isNotEmpty;
    // Determine if the current field is the next one to be filled
    int firstEmptyIndex = pinDigits.indexWhere((digit) => digit.isEmpty);
    if (firstEmptyIndex == -1 && pinDigits.length == pinLength) {
      // All fields are full, no field is "active" for input, but last one might be visually active if error/loading
      firstEmptyIndex = pinLength - 1; // Consider last field active if all full
    } else if (firstEmptyIndex == -1) {
      firstEmptyIndex = 0; // Default to first if something is wrong
    }
    final bool isActive = index == firstEmptyIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: pinLength == 4 ? 15.w : 12.w, // Adjust width for 4 digits
      height: pinLength == 4 ? 15.w : 12.w, // Adjust height for 4 digits
      decoration: BoxDecoration(
        color: hasValue
            ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppTheme.lightTheme.colorScheme.primary
              : hasValue
                  ? AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.5)
                  : AppTheme.lightTheme.colorScheme.outline,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Center(
        child: isLoading && hasValue
            ? SizedBox(
                width: 4.w,
                height: 4.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              )
            : hasValue
                ? Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
      ),
    );
  }
}
