import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../model.dart';
import '../../models/payment_request_dto.dart';
import '../../services/payment_service.dart';
import './widgets/gcash_payment_widget.dart';
import './widgets/manual_payment_widget.dart';
import './widgets/payment_amount_widget.dart';
import './widgets/payment_header_widget.dart';
import './widgets/payment_instructions_widget.dart';
import './widgets/qr_code_display_widget.dart';
import './widgets/qr_scanner_overlay_widget.dart';


class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isQrScannerOpen = false;
  bool _isInstructionsExpanded = false;
  bool _isFlashlightOn = false;
  String _scannedQrCode = '';
  bool _isPaymentSuccessful = false;
  bool _isLoading = true;
  bool _isProcessingPayment = false;

  // Real data from navigation and API
  int? _userId;
  int? _userType;
  int? _loanId;
  int? _transactionId;
  AccountMdl? _currentLoan;
  List<LoanTrxnMdl> _loanTransactions = [];
  LoanTrxnMdl? _selectedTransaction;
  Map<String, dynamic>? _transactionData;
  File? _receiptImage;
  String? _errorMessage;

  // Mock lender GCash details (this could come from API in the future)
  final Map<String, dynamic> lenderGCashDetails = {
    "gcashNumber": "09171234567",
    "accountName": "LoanTracker Pro",
    "qrCodeUrl": "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=09171234567",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentData();
    });
  }

  void _initializePaymentData() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _userId = args['userId'] as int?;
      _userType = args['userType'] as int?;
      _loanId = args['loanId'] as int?;
      _transactionId = args['transactionId'] as int?;
      _currentLoan = args['loan'] as AccountMdl?;

      // Handle transaction data properly - don't cast to LoanTrxnMdl directly
      final transactionArg = args['transaction'];
      if (transactionArg is Map<String, dynamic>) {
        _transactionData = transactionArg;
      } else if (transactionArg is LoanTrxnMdl) {
        // If it's already a LoanTrxnMdl, convert it to Map for consistency
        _transactionData = {
          'id': transactionArg.id,
          'amount': transactionArg.totalDue,
          'principalDue': transactionArg.principalDue,
          'interestDue': transactionArg.interestDue,
          'penaltiesDue': transactionArg.penaltiesDue,
          'serviceFeesDue': transactionArg.serviceFeesDue,
          'date': transactionArg.dueDate,
          'loanID': transactionArg.loanID,
          'isPaid': transactionArg.isPaid,
          'remarks': transactionArg.remarks,
        };
      }

      print('=== PAYMENT METHODS INIT ===');
      print('User ID: $_userId');
      print('Loan ID: $_loanId');
      print('Transaction ID: $_transactionId');
      print('Transaction Data: $_transactionData');

      // Set amount from transaction data if available
      if (_transactionData != null) {
        final amount = _transactionData!['amount'];
        if (amount != null) {
          _amountController.text = (amount as num).toStringAsFixed(2);
        }
      }

      // If we have transaction ID, try to fetch the actual LoanTrxnMdl
      if (_transactionId != null) {
        _fetchLoanTransactions();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Missing payment information. Please try again from the dashboard.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLoanTransactions() async {
    if (_loanId == null) {
      setState(() {
        _errorMessage = 'Loan ID is required for payment processing.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PaymentService.getLoanTransactions(_loanId!);

      if (result['success']) {
        setState(() {
          _loanTransactions = result['transactions'] as List<LoanTrxnMdl>;

          // Find the specific transaction if we have a transaction ID
          if (_transactionId != null) {
            _selectedTransaction = _loanTransactions
                .where((t) => t.id == _transactionId)
                .firstOrNull;
          }

          // If no specific transaction found, use the transaction data we have
          if (_selectedTransaction == null && _transactionData != null) {
            // Create a mock LoanTrxnMdl from the transaction data for compatibility
            _selectedTransaction = _createLoanTrxnFromMap(_transactionData!);
          }

          // If still no transaction, default to the next unpaid one
          if (_selectedTransaction == null && _loanTransactions.isNotEmpty) {
            _selectedTransaction = _loanTransactions
                .where((t) => t.isPaid == false)
                .where((t) => t.dueDate != null && t.dueDate!.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                .firstOrNull;
          }

          if (_selectedTransaction != null && _amountController.text.isEmpty) {
            _amountController.text = _selectedTransaction!.totalDue?.toStringAsFixed(2) ?? '0.00';
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching loan transactions: $e');
      setState(() {
        _errorMessage = 'Failed to load transaction details: $e';
        _isLoading = false;
      });
    }
  }

  LoanTrxnMdl _createLoanTrxnFromMap(Map<String, dynamic> data) {
    return LoanTrxnMdl(
      id: _transactionId,
      loanID: data['loanID'] as int?,
      dueDate: data['date'] as DateTime?,
      totalDue: (data['amount'] as num?)?.toDouble(),
      principalDue: (data['principalDue'] as num?)?.toDouble(),
      interestDue: (data['interestDue'] as num?)?.toDouble(),
      penaltiesDue: (data['penaltiesDue'] as num?)?.toDouble(),
      serviceFeesDue: (data['serviceFeesDue'] as num?)?.toDouble(),
      isPaid: data['status'] == 'Paid',
      remarks: data['remarks'] as String?,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _openQrScanner() {
    setState(() {
      _isQrScannerOpen = true;
    });
  }

  void _closeQrScanner() {
    setState(() {
      _isQrScannerOpen = false;
      _isFlashlightOn = false;
    });
  }

  void _toggleFlashlight() {
    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });
  }

  void _onQrCodeScanned(String qrCode) {
    setState(() {
      _scannedQrCode = qrCode;
      _isQrScannerOpen = false;
      _isFlashlightOn = false;
    });

    _processPayment();
  }

  Future<void> _processPayment() async {
    final transactionIdToUse = _transactionId ?? _selectedTransaction?.id;

    if (transactionIdToUse == null || _userId == null || _loanId == null) {
      _showErrorDialog('Missing payment information. Please try again.');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid payment amount.');
      return;
    }

    // FIX: Round the amount to 2 decimal places to avoid precision issues
    final roundedAmount = double.parse(amount.toStringAsFixed(2));

    setState(() {
      _isProcessingPayment = true;
    });

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Processing Payment...',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₱${roundedAmount.toStringAsFixed(2)}',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );

    try {
      final result = await PaymentService.submitPaymentForApproval(
        loanId: _loanId!,
        userId: _userId!,
        loanTransactionId: transactionIdToUse,
        amount: roundedAmount, // Use rounded amount
        paymentDate: DateTime.now(),
        receiptImage: _receiptImage,
      );

      Navigator.of(context).pop(); // Close processing dialog

      if (result['success']) {
        setState(() {
          _isPaymentSuccessful = true;
        });
        _showPaymentConfirmation(result);
      } else {
        _showErrorDialog(result['message'] ?? 'Payment failed. Please try again.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close processing dialog
      _showErrorDialog('An error occurred while processing payment: $e');
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  void _showPaymentConfirmation(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'schedule',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Payment Submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment is pending approval',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Amount', '₱${_amountController.text}'),
            _buildDetailRow('Payment ID', '${result['paymentId']}'),
            _buildDetailRow('Status', result['status'] ?? 'Pending'),
            _buildDetailRow('Estimated Approval', result['estimatedApprovalTime'] ?? '24-48 hours'),
            if (result['hasReceipt'] == true)
              _buildDetailRow('Receipt', 'Uploaded successfully'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result['message'] ?? 'Your payment has been submitted and is awaiting approval. You will be notified once it has been processed.',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Payment Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showReceiptUploadBottomSheet() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Receipt',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              if (_receiptImage != null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightTheme.colorScheme.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_receiptImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _receiptImage = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Remove'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Use This Image'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      setState(() {
                        _receiptImage = File(image.path);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt photo captured!')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        _receiptImage = File(image.path);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt image selected!')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Payment Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Use transaction data or selected transaction for header
    final transactionForHeader = _transactionData ?? {
      "amount": _selectedTransaction?.totalDue ?? 0.0,
      "date": _selectedTransaction?.dueDate?.toIso8601String().substring(0, 10) ?? "Unknown",
    };

    // Create loan data for header widget
    final loanData = {
      "loanId": _loanId?.toString() ?? "Unknown",
      "borrowerName": _currentLoan?.clientFullName ?? "Unknown",
      "totalAmount": _currentLoan?.total ?? 0.0,
      "amountDue": transactionForHeader["amount"] ?? 0.0,
      "minimumPayment": transactionForHeader["amount"] ?? 0.0,
      "dueDate": transactionForHeader["date"] ?? "Unknown",
      "interestRate": 0.0,
      "remainingBalance": _currentLoan?.total ?? 0.0,
    };

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Sticky Header
                PaymentHeaderWidget(
                  loanData: loanData,
                  onBackPressed: () => Navigator.of(context).pop(),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Amount Section
                        PaymentAmountWidget(
                          controller: _amountController,
                          minimumPayment: (transactionForHeader["amount"] as num?)?.toDouble() ?? 0.0,
                          amountDue: (transactionForHeader["amount"] as num?)?.toDouble() ?? 0.0,
                        ),

                        const SizedBox(height: 24),

                        // Transaction Details
                        if (_selectedTransaction != null || _transactionData != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Breakdown',
                                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildBreakdownRow('Principal',
                                    _selectedTransaction?.principalDue ??
                                        (_transactionData?['principalDue'] as num?)?.toDouble() ?? 0.0),
                                _buildBreakdownRow('Interest',
                                    _selectedTransaction?.interestDue ??
                                        (_transactionData?['interestDue'] as num?)?.toDouble() ?? 0.0),
                                _buildBreakdownRow('Penalties',
                                    _selectedTransaction?.penaltiesDue ??
                                        (_transactionData?['penaltiesDue'] as num?)?.toDouble() ?? 0.0),
                                _buildBreakdownRow('Service Fees',
                                    _selectedTransaction?.serviceFeesDue ??
                                        (_transactionData?['serviceFeesDue'] as num?)?.toDouble() ?? 0.0),
                                const Divider(),
                                _buildBreakdownRow('Total Due',
                                    _selectedTransaction?.totalDue ??
                                        (_transactionData?['amount'] as num?)?.toDouble() ?? 0.0,
                                    isTotal: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Receipt Upload Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.lightTheme.colorScheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt, color: AppTheme.lightTheme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment Receipt',
                                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _receiptImage != null
                                    ? 'Receipt image selected and will be uploaded with payment.'
                                    : 'Upload a receipt image for verification (optional).',
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _showReceiptUploadBottomSheet,
                                  icon: Icon(_receiptImage != null ? Icons.edit : Icons.upload_file),
                                  label: Text(_receiptImage != null ? 'Change Receipt' : 'Upload Receipt'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Payment Instructions
                        PaymentInstructionsWidget(
                          isExpanded: _isInstructionsExpanded,
                          onToggleExpanded: () {
                            setState(() {
                              _isInstructionsExpanded = !_isInstructionsExpanded;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Manual Payment Section
                        ManualPaymentWidget(
                          gcashDetails: lenderGCashDetails,
                          onCopyPressed: _copyToClipboard,
                          onUploadReceiptPressed: _showReceiptUploadBottomSheet,
                        ),

                        const SizedBox(height: 24),

                        // Process Payment Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isPaymentSuccessful || _isProcessingPayment) ? null : _processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isProcessingPayment
                                  ? 'Processing...'
                                  : _isPaymentSuccessful
                                  ? 'Payment Completed'
                                  : 'Process Payment',
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // QR Scanner Overlay
          if (_isQrScannerOpen)
            QrScannerOverlayWidget(
              isFlashlightOn: _isFlashlightOn,
              onClose: _closeQrScanner,
              onToggleFlashlight: _toggleFlashlight,
              onQrCodeScanned: _onQrCodeScanned,
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? AppTheme.lightTheme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
