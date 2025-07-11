import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ConfirmationDialogWidget extends StatefulWidget {
  final String clientName;
  final double amount;
  final String paymentMethod;
  final bool isVisitOnly;
  final VoidCallback onConfirm;

  const ConfirmationDialogWidget({
    super.key,
    required this.clientName,
    required this.amount,
    required this.paymentMethod,
    required this.isVisitOnly,
    required this.onConfirm,
  });

  @override
  State<ConfirmationDialogWidget> createState() =>
      _ConfirmationDialogWidgetState();
}

class _ConfirmationDialogWidgetState extends State<ConfirmationDialogWidget> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinVerified = false;
  bool _isVerifying = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() async {
    if (_pinController.text.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a 4-digit PIN';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    // Mock PIN verification
    await Future.delayed(const Duration(seconds: 1));

    if (_pinController.text == '1234') {
      setState(() {
        _isPinVerified = true;
        _isVerifying = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Invalid PIN. Please try again.';
        _isVerifying = false;
      });
      _pinController.clear();
    }
  }

  void _confirmTransaction() {
    Navigator.of(context).pop();
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.lightTheme.dialogTheme.backgroundColor,
      shape: AppTheme.lightTheme.dialogTheme.shape,
      title: Row(
        children: [
          CustomIconWidget(
            iconName: widget.isVisitOnly ? 'location_on' : 'payment',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isVisitOnly ? 'Confirm Visit' : 'Confirm Payment',
              style: AppTheme.lightTheme.dialogTheme.titleTextStyle,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 80.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction details
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Client', widget.clientName),
                  if (!widget.isVisitOnly) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Amount', '₱${widget.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Method', widget.paymentMethod),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(
                      'Date', DateTime.now().toString().substring(0, 16)),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            if (!_isPinVerified) ...[
              // PIN verification
              Text(
                'Enter your collector PIN to confirm:',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMessage.isNotEmpty
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMessage.isNotEmpty
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMessage.isNotEmpty
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                onChanged: (value) {
                  setState(() {
                    _errorMessage = '';
                  });
                  if (value.length == 4) {
                    _verifyPin();
                  }
                },
              ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'error',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo PIN: 1234',
                        style:
                        AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // PIN verified
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PIN Verified',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ready to confirm transaction',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_isPinVerified)
          ElevatedButton(
            onPressed: _confirmTransaction,
            child:
            Text(widget.isVisitOnly ? 'Confirm Visit' : 'Confirm Payment'),
          )
        else if (!_isVerifying)
          ElevatedButton(
            onPressed: _pinController.text.length == 4 ? _verifyPin : null,
            child: const Text('Verify PIN'),
          )
        else
          ElevatedButton(
            onPressed: null,
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
