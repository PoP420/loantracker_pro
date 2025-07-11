import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentFormWidget extends StatelessWidget {
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String selectedPaymentMethod;
  final List<String> paymentMethods;
  final double outstandingAmount;
  final Function(String) onPaymentMethodChanged;
  final Function(String) onAmountChanged;

  const PaymentFormWidget({
    super.key,
    required this.amountController,
    required this.amountFocusNode,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
    required this.outstandingAmount,
    required this.onPaymentMethodChanged,
    required this.onAmountChanged,
  });

  bool _isValidAmount() {
    if (amountController.text.isEmpty) return true;
    final amount = double.tryParse(amountController.text);
    return amount != null && amount > 0 && amount <= outstandingAmount;
  }

  bool _isOverpayment() {
    if (amountController.text.isEmpty) return false;
    final amount = double.tryParse(amountController.text);
    return amount != null && amount > outstandingAmount;
  }

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
            'Payment Details',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),

          // Payment Amount Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Amount',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: amountController,
                focusNode: amountFocusNode,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '₱ ',
                  prefixStyle:
                  AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isOverpayment()
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isOverpayment()
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isOverpayment()
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
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                ),
                onChanged: onAmountChanged,
                readOnly:
                true, // Make read-only since we're using custom keypad
              ),
              if (_isOverpayment())
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'warning',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Amount exceeds outstanding balance',
                        style:
                        AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              if (amountController.text.isNotEmpty && _isValidAmount())
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Remaining: ₱${(outstandingAmount - (double.tryParse(amountController.text) ?? 0)).toStringAsFixed(2)}',
                        style:
                        AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: 3.h),

          // Payment Method Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...paymentMethods.map((method) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onPaymentMethodChanged(method),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: selectedPaymentMethod == method
                          ? AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedPaymentMethod == method
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline,
                        width: selectedPaymentMethod == method ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: _getPaymentMethodIcon(method),
                          color: selectedPaymentMethod == method
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: selectedPaymentMethod == method
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme
                                  .lightTheme.colorScheme.onSurface,
                              fontWeight: selectedPaymentMethod == method
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selectedPaymentMethod == method)
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash':
        return 'payments';
      case 'GCash':
        return 'qr_code';
      case 'Bank Transfer':
        return 'account_balance';
      default:
        return 'payment';
    }
  }
}
