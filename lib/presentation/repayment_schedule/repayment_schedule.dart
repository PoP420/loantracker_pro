import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/payment_history_card_widget.dart';
import './widgets/search_header_widget.dart';
import '../../services/repayment_schedule_service.dart';

class RepaymentScheduleScreen extends StatefulWidget {
  final int? userId;
  final int? userType;

  const RepaymentScheduleScreen({
    super.key,
    this.userId,
    this.userType,
  });

  @override
  State<RepaymentScheduleScreen> createState() => _RepaymentScheduleScreenState();
}

class _RepaymentScheduleScreenState extends State<RepaymentScheduleScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final PaymentHistoryService _paymentHistoryService = PaymentHistoryService();

  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  String? _errorMessage;
  int? _actualUserId;
  int? _loanId;

  // Filter states
  DateTimeRange? _selectedDateRange;
  RangeValues _amountRange = const RangeValues(0, 100000);
  Set<String> _selectedPaymentMethods = {};
  Set<String> _selectedStatuses = {};

  @override
  void initState() {
    super.initState();
    print('=== PAYMENT HISTORY INIT ===');
    print('Received User ID: ${widget.userId}');
    print('Received User Type: ${widget.userType}');

    _initializeUserId();
    _scrollController.addListener(_onScroll);
  }

  void _initializeUserId() {
    if (widget.userId != null && widget.userId! > 0) {
      _actualUserId = widget.userId;
      _loadPaymentHistory();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        _actualUserId = args['userId'] as int?;
        _loanId = args['loanId'] as int?;
        print('Got userId from route arguments: $_actualUserId');
        print('Got loanId from route arguments: $_loanId');
      }

      if (_actualUserId == null || _actualUserId! <= 0) {
        setState(() {
          _errorMessage = 'User ID not provided. Please login again.';
          _isLoading = false;
        });
        return;
      }

      _loadPaymentHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentHistory() async {
    if (!mounted || _actualUserId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== LOADING PAYMENT HISTORY ===');
      print('Fetching for user ID: $_actualUserId');

      final result = await PaymentHistoryService.getPaymentHistory(_actualUserId!);

      if (result['success']) {
        final paymentHistory = result['paymentHistory'] as List<dynamic>;

        print('=== PAYMENT HISTORY LOADED ===');
        print('Total Transactions Count: ${paymentHistory.length}');

        // **ENHANCED: Separate different types of entries**
        final actualPayments = paymentHistory.where((t) => t['isActualPayment'] == true).toList();
        final scheduledPayments = paymentHistory.where((t) => t['isScheduled'] == true).toList();
        final overduePayments = paymentHistory.where((t) => t['isOverdue'] == true).toList();

        final paidTransactions = actualPayments.where((t) => t['status'] == 'Paid').toList();
        final pendingTransactions = actualPayments.where((t) => t['status'] == 'Pending Review').toList();
        final rejectedTransactions = actualPayments.where((t) => t['status'] == 'Rejected').toList();

        print('Actual Payments - Paid: ${paidTransactions.length}, Pending: ${pendingTransactions.length}, Rejected: ${rejectedTransactions.length}');
        print('Scheduled Payments: ${scheduledPayments.length}');
        print('Overdue Payments: ${overduePayments.length}');

        // Extract loan ID from the first transaction if not already set
        if (_loanId == null && paymentHistory.isNotEmpty) {
          _loanId = paymentHistory.first['loanId'] as int?;
          print('Extracted loan ID: $_loanId');
        }

        setState(() {
          _allTransactions = List<Map<String, dynamic>>.from(paymentHistory);
          _filteredTransactions = List<Map<String, dynamic>>.from(paymentHistory);
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load payment history';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading payment history: $e');
      setState(() {
        _errorMessage = 'Failed to load payment history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreTransactions();
      }
    }
  }

  void _loadMoreTransactions() {
    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage++;
          if (_currentPage > 2) {
            _hasMoreData = false;
          }
        });
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = List.from(_allTransactions);
      } else {
        _filteredTransactions = _allTransactions.where((transaction) {
          final referenceNumber = transaction["referenceNumber"]?.toString().toLowerCase() ?? '';
          final amount = transaction["amount"]?.toString() ?? '';
          final description = transaction["description"]?.toString().toLowerCase() ?? '';
          final paymentMethod = transaction["paymentMethod"]?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return referenceNumber.contains(searchQuery) ||
              amount.contains(searchQuery) ||
              description.contains(searchQuery) ||
              paymentMethod.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        selectedDateRange: _selectedDateRange,
        amountRange: _amountRange,
        selectedPaymentMethods: _selectedPaymentMethods,
        selectedStatuses: _selectedStatuses,
        onApplyFilters: _applyFilters,
        onResetFilters: _resetFilters,
      ),
    );
  }

  void _applyFilters({
    DateTimeRange? dateRange,
    RangeValues? amountRange,
    Set<String>? paymentMethods,
    Set<String>? statuses,
  }) {
    setState(() {
      _selectedDateRange = dateRange;
      _amountRange = amountRange ?? _amountRange;
      _selectedPaymentMethods = paymentMethods ?? {};
      _selectedStatuses = statuses ?? {};

      _filteredTransactions = _allTransactions.where((transaction) {
        bool matchesDate = true;
        bool matchesAmount = true;
        bool matchesPaymentMethod = true;
        bool matchesStatus = true;

        if (_selectedDateRange != null) {
          final transactionDate = transaction["paymentDate"] as DateTime;
          matchesDate = transactionDate.isAfter(
              _selectedDateRange!.start.subtract(Duration(days: 1))) &&
              transactionDate
                  .isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
        }

        final amount = (transaction["amount"] as num?)?.toDouble() ?? 0.0;
        matchesAmount =
            amount >= _amountRange.start && amount <= _amountRange.end;

        if (_selectedPaymentMethods.isNotEmpty) {
          final method = transaction["paymentMethod"]?.toString() ?? '';
          matchesPaymentMethod = _selectedPaymentMethods.contains(method);
        }

        if (_selectedStatuses.isNotEmpty) {
          final status = transaction["status"]?.toString() ?? '';
          matchesStatus = _selectedStatuses.contains(status);
        }

        return matchesDate &&
            matchesAmount &&
            matchesPaymentMethod &&
            matchesStatus;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedDateRange = null;
      _amountRange = const RangeValues(0, 100000);
      _selectedPaymentMethods = {};
      _selectedStatuses = {};
      _filteredTransactions = List.from(_allTransactions);
    });
  }

  Future<void> _onRefresh() async {
    await _loadPaymentHistory();
  }

  void _onTransactionTap(Map<String, dynamic> transaction) {
    final isPending = transaction['isPending'] == true;
    final isOverdue = transaction['isOverdue'] == true;
    final isScheduled = transaction['isScheduled'] == true;
    final status = transaction['status'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isOverdue
                ? 'Overdue Payment'
                : isScheduled
                ? 'Scheduled Payment'
                : isPending
                ? 'Pending Payment'
                : 'Transaction Details'
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOverdue) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This payment is overdue. Please pay immediately to avoid additional penalties.',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ] else if (isScheduled) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a scheduled payment. You can pay early to avoid any delays.',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              _buildDetailRow('Reference', transaction["referenceNumber"]),
              _buildDetailRow('Amount', '₱${(transaction["amount"] as num).toStringAsFixed(2)}'),
              if (!isPending && !isOverdue && !isScheduled) _buildDetailRow('Method', transaction["paymentMethod"]),
              _buildDetailRow('Status', transaction["status"]),
              _buildDetailRow('Description', transaction["description"]),
              _buildDetailRow(
                  (isPending || isOverdue || isScheduled) ? 'Due Date' : 'Date',
                  _formatDate(transaction["paymentDate"] as DateTime)
              ),
              if (transaction["remarks"] != null && transaction["remarks"].toString().isNotEmpty)
                _buildDetailRow('Remarks', transaction["remarks"]),
              if (isPending || isOverdue || isScheduled) ...[
                SizedBox(height: 16),
                Text('Payment Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (transaction["principalDue"] != null)
                  _buildDetailRow('Principal', '₱${(transaction["principalDue"] as num).toStringAsFixed(2)}'),
                if (transaction["interestDue"] != null)
                  _buildDetailRow('Interest', '₱${(transaction["interestDue"] as num).toStringAsFixed(2)}'),
                if (transaction["penaltiesDue"] != null && (transaction["penaltiesDue"] as num) > 0)
                  _buildDetailRow('Penalties', '₱${(transaction["penaltiesDue"] as num).toStringAsFixed(2)}'),
                if (transaction["serviceFeesDue"] != null && (transaction["serviceFeesDue"] as num) > 0)
                  _buildDetailRow('Service Fees', '₱${(transaction["serviceFeesDue"] as num).toStringAsFixed(2)}'),
              ],
            ],
          ),
        ),
          actions: [
            if ((isPending || isOverdue || isScheduled) && status?.toLowerCase() != 'paid')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Future.microtask(() => _navigateToPaymentMethods(transaction));
                },
                icon: Icon(
                  isOverdue ? Icons.priority_high : isScheduled ? Icons.schedule : Icons.payment,
                  color: Colors.white,
                ),
                label: Text(isOverdue ? 'Pay Now!' : isScheduled ? 'Pay Early' : 'Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue
                      ? AppTheme.lightTheme.colorScheme.error
                      : isScheduled
                      ? Colors.blue
                      : AppTheme.lightTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ]

      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }

  void _navigateToPaymentMethods(Map<String, dynamic> transaction) {
    print('=== NAVIGATING TO PAYMENT METHODS ===');
    print('Transaction: ${transaction["id"]}');
    print('User ID: $_actualUserId');
    print('Loan ID: $_loanId');
    print('Transaction ID: ${transaction["transactionId"]}');
    print('Amount: ${transaction["amount"]}');

    // Validate required parameters
    if (_actualUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User session expired. Please login again.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
      return;
    }

    if (_loanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan information not available. Please refresh and try again.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
      return;
    }

    final transactionId = transaction["transactionId"];
    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction ID not available. Please try again.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
      return;
    }

    // Navigate with all required parameters
    Navigator.pushNamed(context, '/payment-methods', arguments: {
      'userId': _actualUserId,
      'userType': widget.userType,
      'loanId': _loanId,
      'transactionId': transactionId,
      'amount': transaction["amount"],
      'isOverdue': transaction["isOverdue"] == true,
      'isScheduled': transaction["isScheduled"] == true,
      'transaction': transaction,
    }).then((_) {
      // Refresh payment history when returning from payment screen
      _loadPaymentHistory();
    });
  }

  void _onQuickAction(Map<String, dynamic> transaction, String action) {
    print('=== QUICK ACTION TRIGGERED ===');
    print('Action: $action');
    print('Transaction ID: ${transaction["id"]}');

    switch (action) {
      case 'Pay Now':
        _navigateToPaymentMethods(transaction);
        break;
      case 'View Receipt':
        _showReceiptDialog(transaction);
        break;
      case 'Download PDF':
        _downloadReceipt(transaction);
        break;
      case 'Share Details':
        _shareTransactionDetails(transaction);
        break;
      case 'Dispute':
        _initiateDispute(transaction);
        break;
      case 'Contact Support':
        _contactSupport(transaction);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$action for ${transaction["referenceNumber"]}'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  void _contactSupport(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Support'),
        content: Text('Would you like to contact support regarding this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Support contacted for ${transaction["referenceNumber"]}'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Contact'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receipt'),
        content: Text('Receipt functionality will be implemented when receipt URLs are available from the API.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _downloadReceipt(Map<String, dynamic> transaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareTransactionDetails(Map<String, dynamic> transaction) {
    final details = '''
Transaction Details:
Reference: ${transaction["referenceNumber"]}
Amount: ₱${(transaction["amount"] as num).toStringAsFixed(2)}
Date: ${_formatDate(transaction["paymentDate"] as DateTime)}
Status: ${transaction["status"]}
Description: ${transaction["description"]}
''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality: $details'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _initiateDispute(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dispute Transaction'),
        content: Text('Would you like to report an issue with this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dispute reported for ${transaction["referenceNumber"]}'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Report'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SearchHeaderWidget(
              searchController: _searchController,
              onSearch: _onSearch,
              onFilterTap: _showFilterBottomSheet,
              hasActiveFilters: _selectedDateRange != null ||
                  _selectedPaymentMethods.isNotEmpty ||
                  _selectedStatuses.isNotEmpty,
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _filteredTransactions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.lightTheme.primaryColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                      horizontal: 4.w, vertical: 2.h),
                  itemCount: _filteredTransactions.length +
                      (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredTransactions.length) {
                      return _buildLoadingIndicator();
                    }

                    final transaction = _filteredTransactions[index];
                    return PaymentHistoryCardWidget(
                      transaction: transaction,
                      onTap: () => _onTransactionTap(transaction),
                      onQuickAction: (action) =>
                          _onQuickAction(transaction, action),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.primaryColor,
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading payment history...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.error,
            ),
            SizedBox(height: 3.h),
            Text(
              'Error Loading History',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                if (_actualUserId != null) {
                  _loadPaymentHistory();
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false
                  );
                }
              },
              icon: Icon(_actualUserId != null ? Icons.refresh : Icons.login),
              label: Text(_actualUserId != null ? 'Retry' : 'Login Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'receipt_long',
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.outline,
          ),
          SizedBox(height: 3.h),
          Text(
            'No Payment History',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your payment history will appear here\nonce you make your first payment.',
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/payment-methods', arguments: {
              'userId': _actualUserId,
              'userType': widget.userType,
              'loanId': _loanId,
            }),
            child: Text('Make Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard',
            size: 6.w,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'dashboard',
            size: 6.w,
            color: AppTheme.lightTheme.primaryColor,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'history',
            size: 6.w,
            color: AppTheme.lightTheme.primaryColor,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'history',
            size: 6.w,
            color: AppTheme.lightTheme.primaryColor,
          ),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            size: 6.w,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'person',
            size: 6.w,
            color: AppTheme.lightTheme.primaryColor,
          ),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pop(context);
            break;
          case 1:
            break;
          case 2:
            Navigator.pushNamed(context, '/profile', arguments: {});
            break;
        }
      },
    );
  }
}
