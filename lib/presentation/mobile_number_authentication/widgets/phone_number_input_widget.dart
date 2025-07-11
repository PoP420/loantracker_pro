import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhoneNumberInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isValid;
  final bool hasError;
  final Function(String) onSubmitted;

  const PhoneNumberInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isValid,
    required this.hasError,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
        PhoneNumberFormatter(),
      ],
      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppTheme.lightTheme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: '9XX XXX XXXX',
        hintStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
              .withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: AppTheme.lightTheme.colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError
                ? AppTheme.lightTheme.colorScheme.error
                : AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError
                ? AppTheme.lightTheme.colorScheme.error
                : AppTheme.lightTheme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.error,
            width: 2,
          ),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? Container(
                margin: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isValid
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomIconWidget(
                  iconName: isValid ? 'check' : 'close',
                  color: Colors.white,
                  size: 4.w,
                ),
              )
            : null,
      ),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 6) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
