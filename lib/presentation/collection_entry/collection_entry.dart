import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../model.dart';
import '../../model/transaction.dart';
import './widgets/client_header_widget.dart';
import './widgets/client_verification_widget.dart';
import './widgets/confirmation_dialog_widget.dart';
import './widgets/notes_section_widget.dart';
import './widgets/numeric_keypad_widget.dart';
import './widgets/payment_form_widget.dart';
import './widgets/photo_capture_widget.dart';

class CollectionEntry extends StatefulWidget {
  // Make parameters optional to maintain compatibility with existing routes
  final AssignedLoanMdl? loan;
  final int? collectorId;
  final Transaction? selectedTransaction;

  const CollectionEntry({
    super.key,
    this.loan,
    this.collectorId,
    this.selectedTransaction,
  });

  @override
  State<CollectionEntry> createState() => _CollectionEntryState();
}

class _CollectionEntryState extends State<CollectionEntry> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  String _selectedPaymentMethod = 'Cash';
  bool _isNotesExpanded = false;
  bool _isMarkedAsVisited = false;
  bool _isOfflineMode = false;
  String _capturedPhotoPath = '';
  bool _isLoading = false;



  // Data extracted from route arguments or widget parameters
  AssignedLoanMdl? _currentLoan;
  int? _currentCollectorId;

  final List<String> _paymentMethods = ['Cash', 'GCash'];

  // Convert loan data to client data format for widgets
  Map<String, dynamic> get _clientData {
    final loan = _currentLoan;
    if (loan == null) {
      return _getDefaultClientData();
    }

    return {
      "id": loan.client?.userId?.toString() ?? "Unknown",
      "name": loan.client?.fullName ?? "Unknown Client",
      "photo": "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400", // Default photo
      "loanId": loan.loan?.loanId?.toString() ?? "Unknown",
      "outstandingAmount": loan.loan?.total ?? 0.0,
      "dueDate": DateTime.now().add(Duration(days: 7)).toString().substring(0, 10), // Mock due date
      "address": loan.client?.address ?? "Address not available",
      "phoneNumber": loan.client?.userName ?? "N/A",
      "loanType": "Personal Loan", // This would come from loan type lookup
      "installmentAmount": (loan.loan?.total ?? 0.0) / 12, // Mock calculation
      "lastPaymentDate": DateTime.now().subtract(Duration(days: 30)).toString().substring(0, 10),
      "paymentHistory": [] // This would be fetched from API
    };
  }

  Map<String, dynamic> _getDefaultClientData() {
    return {
      "id": "demo",
      "name": "Demo Client",
      "photo": "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
      "loanId": "DEMO001",
      "outstandingAmount": 5000.0,
      "dueDate": DateTime.now().add(Duration(days: 7)).toString().substring(0, 10),
      "address": "Demo Address",
      "phoneNumber": "09123456789",
      "loanType": "Personal Loan",
      "installmentAmount": 500.0,
      "lastPaymentDate": DateTime.now().subtract(Duration(days: 30)).toString().substring(0, 10),
      "paymentHistory": []
    };
  }

  @override
  void initState() {
    super.initState();
    _extractRouteArguments();
    _checkConnectivity();
    if (widget.selectedTransaction != null) {
      _amountController.text =
          (widget.selectedTransaction!.totalDue ?? 0.0).toStringAsFixed(2);
    }
  }

  void _extractRouteArguments() {
    // First try to use widget parameters
    if (widget.loan != null && widget.collectorId != null) {
      _currentLoan = widget.loan;
      _currentCollectorId = widget.collectorId;
      return;
    }

    // Then try to extract from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _currentLoan = args['loan'] as AssignedLoanMdl?;
          _currentCollectorId = args['collectorId'] as int?;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _amountFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _checkConnectivity() {
    // Mock connectivity check
    setState(() {
      _isOfflineMode = false; // Simulate online mode
    });
  }

  void _onKeypadTap(String value) {
    if (value == 'clear') {
      _amountController.clear();
    } else if (value == 'backspace') {
      if (_amountController.text.isNotEmpty) {
        _amountController.text = _amountController.text
            .substring(0, _amountController.text.length - 1);
      }
    } else {
      if (value == '.' && _amountController.text.contains('.')) return;
      _amountController.text += value;
    }
    _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length));
  }

  bool _validateAmount() {
    if (_amountController.text.isEmpty) return false;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return false;
    final outstandingAmount = _currentLoan?.loan?.total ?? _clientData["outstandingAmount"] as double;
    return amount <= outstandingAmount;
  }

  void _showConfirmationDialog() {
    if (!_validateAmount() && !_isMarkedAsVisited) {
      _showErrorDialog(
          'Please enter a valid payment amount or mark as visited.');
      return;
    }

    showDialog(
        context: context,
        builder: (context) => ConfirmationDialogWidget(
            clientName: _clientData["name"] as String,
            amount: _amountController.text.isNotEmpty
                ? double.parse(_amountController.text)
                : 0.0,
            paymentMethod: _selectedPaymentMethod,
            isVisitOnly: _isMarkedAsVisited && _amountController.text.isEmpty,
            onConfirm: _processPayment));
  }

  void _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_amountController.text.isNotEmpty) {
        // Process actual payment
        await _submitPayment();
      } else {
        // Just mark as visited
        await _markAsVisited();
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to process payment: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }




  Future<void> _submitPayment() async {
    if (_currentLoan == null || _currentCollectorId == null || widget.selectedTransaction == null) {
      await Future.delayed(const Duration(seconds: 2));
      print('Demo payment submitted: ${_amountController.text}');
      return;
    }

    try {
      final paymentData = {
        'UserID': _currentLoan!.client?.userId,
        'LoanID': _currentLoan!.loan?.loanId,
        'LoanTransactionID': widget.selectedTransaction!.id,
        'Amount': double.parse(_amountController.text),
        'PaymentDate': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('http://192.168.1.8:5000/api/Collector/payments'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(paymentData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit payment: ${response.statusCode}');
      }

      print('Payment submitted successfully');
    } catch (e) {
      print('Error submitting payment: $e');
      rethrow;
    }
  }

  Future<void> _markAsVisited() async {
    // This would typically call an API to mark the client as visited
    await Future.delayed(const Duration(seconds: 1));
    print('Client marked as visited');
  }

  void _showSuccessDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  size: 24),
              const SizedBox(width: 8),
              Text('Success',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.tertiary)),
            ]),
            content: Text(
                _amountController.text.isNotEmpty
                    ? 'Payment of ₱${_amountController.text} has been recorded successfully.'
                    : 'Visit has been marked successfully.',
                style: AppTheme.lightTheme.textTheme.bodyMedium),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Return to dashboard
                  },
                  child: const Text('Continue')),
            ]));
  }

  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              CustomIconWidget(
                  iconName: 'error',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 24),
              const SizedBox(width: 8),
              Text('Error',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error)),
            ]),
            content: Text(message,
                style: AppTheme.lightTheme.textTheme.bodyMedium),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK')),
            ]));
  }

  void _onBackPressed() {
    if (_amountController.text.isNotEmpty || _notesController.text.isNotEmpty) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              backgroundColor: AppTheme.lightTheme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Discard Changes?',
                  style: AppTheme.lightTheme.textTheme.titleLarge),
              content: Text(
                  'You have unsaved changes. Are you sure you want to go back?',
                  style: AppTheme.lightTheme.textTheme.bodyMedium),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text('Discard',
                        style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.error))),
              ]));
    } else {
      Navigator.of(context).pop();
    }
  }




  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _onBackPressed();
          return false;
        },
        child: Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            appBar: AppBar(
                backgroundColor:
                AppTheme.lightTheme.appBarTheme.backgroundColor,
                elevation: AppTheme.lightTheme.appBarTheme.elevation,
                leading: IconButton(
                    onPressed: _onBackPressed,
                    icon: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
                        size: 24)),
                title: Text('Collection Entry',
                    style: AppTheme.lightTheme.appBarTheme.titleTextStyle),
                actions: [
                  if (_isOfflineMode)
                    Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          CustomIconWidget(iconName: 'cloud_off', size: 20),
                          const SizedBox(width: 4),
                          Text('Offline',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith()),
                        ])),
                ]),
            body: SafeArea(
                child: Column(children: [
                  // Client Header
                  ClientHeaderWidget(
                      clientData: _clientData, isOfflineMode: _isOfflineMode),

                  // Main Content
                  Expanded(
                      child: SingleChildScrollView(
                          padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Client Verification
                                ClientVerificationWidget(clientData: _clientData),

                                SizedBox(height: 3.h),

                                // Payment Form
                                PaymentFormWidget(
                                    amountController: _amountController,
                                    amountFocusNode: _amountFocusNode,
                                    selectedPaymentMethod: _selectedPaymentMethod,
                                    paymentMethods: _paymentMethods,
                                    outstandingAmount: _clientData["outstandingAmount"] as double,
                                    onPaymentMethodChanged: (value) {
                                      setState(() {
                                        _selectedPaymentMethod = value;
                                      });
                                    },
                                    onAmountChanged: (value) {
                                      setState(() {});
                                    }),

                                SizedBox(height: 3.h),

                                // Numeric Keypad
                                NumericKeypadWidget(onKeyTap: _onKeypadTap),

                                SizedBox(height: 3.h),

                                // Notes Section
                                NotesSectionWidget(
                                    notesController: _notesController,
                                    notesFocusNode: _notesFocusNode,
                                    isExpanded: _isNotesExpanded,
                                    onExpandToggle: () {
                                      setState(() {
                                        _isNotesExpanded = !_isNotesExpanded;
                                      });
                                    }),

                                SizedBox(height: 3.h),

                                // Photo Capture
                                PhotoCaptureWidget(
                                    capturedPhotoPath: _capturedPhotoPath,
                                    onPhotoCapture: (path) {
                                      setState(() {
                                        _capturedPhotoPath = path;
                                      });
                                    }),

                                SizedBox(height: 3.h),

                                // Mark as Visited Toggle
                                Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                        color: AppTheme.lightTheme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppTheme
                                                .lightTheme.colorScheme.outline,
                                            width: 1)),
                                    child: Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text('Mark as Visited',
                                                    style: AppTheme.lightTheme.textTheme
                                                        .titleMedium),
                                                const SizedBox(height: 4),
                                                Text(
                                                    'Record visit attempt without payment',
                                                    style: AppTheme.lightTheme.textTheme
                                                        .bodySmall),
                                              ])),
                                      Switch(
                                          value: _isMarkedAsVisited,
                                          onChanged: (value) {
                                            setState(() {
                                              _isMarkedAsVisited = value;
                                            });
                                          }),
                                    ])),

                                SizedBox(height: 4.h),
                              ]))),

                  // Bottom Action Button
                  Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          border: Border(
                              top: BorderSide(
                                  color: AppTheme.lightTheme.colorScheme.outline,
                                  width: 1))),
                      child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed:
                              _isLoading ? null : _showConfirmationDialog,
                              style: AppTheme.lightTheme.elevatedButtonTheme.style
                                  ?.copyWith(
                                  minimumSize: WidgetStateProperty.all(
                                      Size(double.infinity, 6.h))),
                              child: _isLoading
                                  ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.lightTheme.colorScheme
                                              .onPrimary)))
                                  : Text(_amountController.text.isNotEmpty || _isMarkedAsVisited ? 'Submit Entry' : 'Mark as Visited',
                                  style: AppTheme.lightTheme.elevatedButtonTheme.style?.textStyle?.resolve({})?.copyWith(fontSize: 16, fontWeight: FontWeight.w600))))),
                ]))));
  }
}
