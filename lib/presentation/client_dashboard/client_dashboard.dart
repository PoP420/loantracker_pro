import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../model.dart';
import '../../core/app_export.dart';
import './widgets/dashboard_header_widget.dart';
import './widgets/loan_summary_card_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/recent_transactions_widget.dart';
import '../../models/payment_request_dto.dart';

class ClientDashboard extends StatefulWidget {
  final int userId;
  final int userType;

  const ClientDashboard({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with TickerProviderStateMixin {

  int _selectedIndex = 0;
  bool _isRefreshing = false;
  late TabController _tabController;

  // API and Data State
  final String _baseUrl = "http://192.168.1.102:5000/api";

  AccountMdl? _currentLoan;
  List<LoanTrxnMdl> _loanSchedule = [];
  List<TrxnHistory> _recentPayments = [];
  LoanTrxnMdl? _nextPaymentDue;
  double _outstandingBalance = 0.0;
  List<LoanTrxnMdl> _loanTransactions = [];
  bool _isLoadingTransactions = false;

  bool _isLoading = true;
  String? _errorMessage;
  String _lastSyncTime = DateTime.now().toString().substring(0, 19);
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    print('=== CLIENT DASHBOARD INIT ===');
    print('Received User ID: ${widget.userId}');
    print('Received User Type: ${widget.userType}');

    _tabController = TabController(length: 4, vsync: this);
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== FETCHING COMPREHENSIVE LOAN DATA ===');
      print('User ID: ${widget.userId}');

      final loansUri = Uri.parse('$_baseUrl/Loans/client/${widget.userId}');
      print('Enhanced Loans URI: $loansUri');

      final loansResponse = await http.get(
        loansUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('=== ENHANCED API RESPONSE ===');
      print('Status Code: ${loansResponse.statusCode}');
      print('Response Body: ${loansResponse.body}');

      if (loansResponse.statusCode == 200) {
        final responseData = jsonDecode(loansResponse.body);

        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final List<dynamic> loansData = responseData['data'] ?? [];

          print('=== PARSING LOAN DATA ===');
          print('Number of loans: ${loansData.length}');

          if (loansData.isNotEmpty) {
            final loanData = loansData.first as Map<String, dynamic>;
            print('First loan data keys: ${loanData.keys.toList()}');

            // Create AccountMdl from comprehensive data
            _currentLoan = AccountMdl(
              loanId: loanData['loanId'],
              userId: loanData['userId'],
              clientFullName: loanData['clientFullName'] ?? 'Unknown Client',
              amount: (loanData['loanAmount'] as num?)?.toDouble(),
              total: (loanData['total'] as num?)?.toDouble(),
              status: loanData['status'] ?? 'Unknown',
            );

            // Extract outstanding balance
            _outstandingBalance = (loanData['outstandingBalance'] as num?)?.toDouble() ?? 0.0;

            // Extract transactions and sort in ASCENDING order (oldest first)
            final transactions = loanData['loanTransactions'] as List<dynamic>? ?? [];
            print('Number of transactions: ${transactions.length}');

            _loanSchedule = transactions.map((t) {
              return LoanTrxnMdl(
                id: t['id'],
                loanID: t['loanID'] ?? loanData['loanId'],
                principalDue: (t['principalDue'] as num?)?.toDouble(),
                interestDue: (t['interestDue'] as num?)?.toDouble(),
                penaltiesDue: (t['penaltiesDue'] as num?)?.toDouble(),
                totalDue: (t['totalDue'] as num?)?.toDouble(),
                dueDate: t['dueDate'] != null ? DateTime.tryParse(t['dueDate']) : null,
                isPaid: t['isPaid'] ?? false,
                remarks: t['remarks'],
                weeklyDue: (t['weeklyDue'] as num?)?.toDouble(),
                serviceFeesDue: (t['serviceFeesDue'] as num?)?.toDouble(),
              );
            }).toList();

            // Sort transactions in ASCENDING order by due date (oldest first)
            _loanSchedule.sort((a, b) {
              if (a.dueDate == null && b.dueDate == null) return 0;
              if (a.dueDate == null) return 1;
              if (b.dueDate == null) return -1;
              return a.dueDate!.compareTo(b.dueDate!); // Ascending order
            });

            // Get the FIRST unpaid transaction (earliest due date)
            _nextPaymentDue = _getNextUnpaidTransaction();

            print('=== TRANSACTION SORTING ===');
            print('Total transactions: ${_loanSchedule.length}');
            if (_loanSchedule.isNotEmpty) {
              print('First transaction date: ${_loanSchedule.first.dueDate}');
              print('Last transaction date: ${_loanSchedule.last.dueDate}');
            }
            print('Next payment due: ${_nextPaymentDue?.dueDate} - Amount: ${_nextPaymentDue?.totalDue}');

            // Extract payment history - but don't use it for Recent Transactions
            // The RecentTransactionsWidget will fetch real payment data from API
            final payments = loanData['paymentHistory'] as List<dynamic>? ?? [];
            print('Number of payments: ${payments.length}');

            _recentPayments = payments.map((p) {
              return TrxnHistory(
                id: p['id'],
                loanID: p['loanID'] ?? loanData['loanId'],
                trxnID: p['trxnID'],
                amount: (p['amount'] as num?)?.toDouble(),
                pDate: p['pDate'],
                userID: p['userID'],
              );
            }).toList();

            // Sort payment history in ASCENDING order (oldest first)
            _recentPayments.sort((a, b) {
              if (a.pDate == null && b.pDate == null) return 0;
              if (a.pDate == null) return 1;
              if (b.pDate == null) return -1;
              try {
                final dateA = DateTime.parse(a.pDate!);
                final dateB = DateTime.parse(b.pDate!);
                return dateA.compareTo(dateB); // Ascending order
              } catch (e) {
                return 0;
              }
            });

            print('=== DATA LOADED SUCCESSFULLY ===');
            print('Loan ID: ${_currentLoan?.loanId}');
            print('Client Name: ${_currentLoan?.clientFullName}');
            print('Outstanding Balance: $_outstandingBalance');
            print('Transactions: ${_loanSchedule.length}');
            print('Payments: ${_recentPayments.length}');
            print('Next Payment Due: ${_nextPaymentDue?.totalDue}');

            setState(() {
              _isConnected = true;
              _errorMessage = null;
            });

          } else {
            setState(() {
              _errorMessage = 'No loan data found in response';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Invalid response format from server';
          });
        }
      } else if (loansResponse.statusCode == 404) {
        final errorData = jsonDecode(loansResponse.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'User or loans not found';
          _isConnected = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error ${loansResponse.statusCode}';
          _isConnected = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isConnected = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _lastSyncTime = DateTime.now().toString().substring(0, 19);
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    HapticFeedback.lightImpact();
    await _fetchDashboardData();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
      // Dashboard - already here
        break;
      case 1:
      // Navigate to payment methods with loan data
        _navigateToPaymentMethods();
        break;
      case 2:
      // Navigate to payment history
        Navigator.pushNamed(context, '/payment-history', arguments: {
          'userId': widget.userId,
          'userType': widget.userType,
          'loanId': _currentLoan?.loanId,
        });
        break;
      case 3:
      // Profile - implement as needed
        Navigator.pushNamed(context, '/profile', arguments: {});
        break;
    }
  }

  void _showStatement(){
    if (_currentLoan != null) {
      final nextTransaction = _getNextUnpaidTransaction();
      Navigator.pushNamed(context, '/statement-of-account', arguments: {
        'userId': widget.userId,
        'userType': widget.userType,
        'loanId': _currentLoan!.loanId,
        'loan': _currentLoan,
        'transaction': nextTransaction,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active loan found for payment')),
      );
    }
  }

  void _navigateToReceiptUpload() {
    if (_currentLoan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active loan found')),
      );
      return;
    }

    final nextTransaction = _getNextUnpaidTransaction();

    print('=== NAVIGATING TO RECEIPT UPLOAD ===');
    print('Loan ID: ${_currentLoan!.loanId}');
    print('Next Transaction: ${nextTransaction?.id}');
    print('Amount: ${nextTransaction?.totalDue}');

    Navigator.pushNamed(context, '/receipt-upload', arguments: {
      'userId': widget.userId,
      'userType': widget.userType,
      'loanId': _currentLoan!.loanId,
      'transactionId': nextTransaction?.id,
      'amount': nextTransaction?.totalDue ?? 0.0,
      'dueDate': nextTransaction?.dueDate?.toIso8601String().substring(0, 10) ?? 'N/A',
      'paymentMethod': 'GCash',
      'loan': _currentLoan,
      'transaction': nextTransaction,
    }).then((_) {
      _fetchDashboardData();
    });
  }

  void _navigateToPaymentMethods() {
    if (_currentLoan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active loan found for payment')),
      );
      return;
    }

    final nextTransaction = _getNextUnpaidTransaction();

    if (nextTransaction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending payments found')),
      );
      return;
    }

    print('=== NAVIGATING TO PAYMENT METHODS ===');
    print('Using next transaction: ${nextTransaction.id}');
    print('Due date: ${nextTransaction.dueDate}');
    print('Amount: ${nextTransaction.totalDue}');
    print('Loan ID: ${_currentLoan!.loanId}');

    final transactionData = {
      'id': nextTransaction.id?.toString() ?? 'TXN_${nextTransaction.id}',
      'date': nextTransaction.dueDate ?? DateTime.now(),
      'amount': nextTransaction.totalDue ?? 0.0,
      'paymentMethod': 'Pending',
      'status': _isTransactionOverdue(nextTransaction) ? 'Overdue' : 'Pending',
      'referenceNumber': 'TXN-${nextTransaction.id}',
      'description': 'Scheduled Payment',
      'receiptUrl': null,
      'loanID': nextTransaction.loanID,
      'userID': widget.userId,
      'remarks': nextTransaction.remarks,
      'isPending': !_isTransactionOverdue(nextTransaction),
      'isOverdue': _isTransactionOverdue(nextTransaction),
      'principalDue': nextTransaction.principalDue ?? 0.0,
      'interestDue': nextTransaction.interestDue ?? 0.0,
      'penaltiesDue': nextTransaction.penaltiesDue ?? 0.0,
      'serviceFeesDue': nextTransaction.serviceFeesDue ?? 0.0,
      'transactionId': nextTransaction.id,
    };

    Navigator.pushNamed(context, '/payment-methods', arguments: {
      'userId': widget.userId,
      'userType': widget.userType,
      'loanId': _currentLoan!.loanId,
      'transactionId': nextTransaction.id,
      'amount': nextTransaction.totalDue,
      'isOverdue': _isTransactionOverdue(nextTransaction),
      'transaction': transactionData,
      'loan': _currentLoan,
    }).then((_) {
      _fetchDashboardData();
    });
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.support_agent, color: AppTheme.lightTheme.colorScheme.primary),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with your loan or payments?'),
            SizedBox(height: 16),
            _buildSupportOption(Icons.phone, 'Phone', '+63 123 456 7890'),
            _buildSupportOption(Icons.email, 'Email', 'support@loantracker.com'),
            _buildSupportOption(Icons.chat, 'Live Chat', 'Available 24/7'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppTheme.lightTheme.colorScheme.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For payment issues, please have your loan ID and transaction details ready.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening support chat...')),
              );
            },
            child: Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  LoanTrxnMdl? _getNextUnpaidTransaction() {
    if (_loanSchedule.isEmpty) return null;

    final unpaidTransactions = _loanSchedule
        .where((t) => t.isPaid == false)
        .toList();

    if (unpaidTransactions.isEmpty) return null;

    return unpaidTransactions.first;
  }

  bool _isTransactionOverdue(LoanTrxnMdl transaction) {
    if (transaction.dueDate == null) return false;
    return DateTime.now().isAfter(transaction.dueDate!);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userType != 10) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 60, color: AppTheme.lightTheme.colorScheme.error),
                const SizedBox(height: 20),
                Text(
                  "Access Denied",
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "This dashboard is intended for client users only.",
                  style: AppTheme.lightTheme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.lightTheme.colorScheme.primary,
          child: _isLoading && !_isRefreshing
              ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.colorScheme.primary
              )
          )
              : _errorMessage != null && _currentLoan == null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                      iconName: 'error_outline',
                      size: 48,
                      color: AppTheme.lightTheme.colorScheme.error
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'Error',
                      style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error
                      )
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: _fetchDashboardData,
                  )
                ],
              ),
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DashboardHeaderWidget(
                  clientName: _currentLoan?.clientFullName ?? "Client",
                  lastSyncTime: _lastSyncTime,
                  isConnected: _isConnected,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      if (_currentLoan != null)
                        LoanSummaryCardWidget(
                          loanId: _currentLoan!.loanId ?? 0,
                          userId: _currentLoan!.userId ?? 0,
                          loanStatus: _currentLoan!.status ?? "Unknown",
                          nextPaymentAmount: _nextPaymentDue?.totalDue ?? 0.0,
                          nextPaymentDate: _nextPaymentDue?.dueDate?.toIso8601String().substring(0, 10) ?? "N/A",
                          outstandingBalance: _outstandingBalance,
                        )
                      else if (!_isLoading)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Text(
                              "No active loan found.",
                              style: AppTheme.lightTheme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      QuickActionsWidget(
                        onMakePayment: _navigateToPaymentMethods,
                        onViewSchedule: () {
                          Navigator.pushNamed(context, '/repayment-schedule', arguments: {
                            'userId': widget.userId,
                            'userType': widget.userType,
                            'loanId': _currentLoan?.loanId,
                          });
                        },
                        onUploadReceipt: _navigateToReceiptUpload,
                        onContactSupport: _showSupportDialog,
                        onViewStatement: _showStatement,
                      ),

                      const SizedBox(height: 24),
                      // **FIX: Use the enhanced RecentTransactionsWidget that fetches real payment data**
                      RecentTransactionsWidget(
                        transactions: [], // Pass empty list - widget will fetch real data
                        userId: widget.userId, // **CRITICAL: Pass userId so widget can fetch real payment data**
                        onViewAll: () {
                          Navigator.pushNamed(context, '/payment-history', arguments: {
                            'userId': widget.userId,
                            'userType': widget.userType,
                            'loanId': _currentLoan?.loanId,
                          });
                        },
                        onMakeFirstPayment: _navigateToPaymentMethods,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: _currentLoan == null || _isLoading
          ? null
          : FloatingActionButton.extended(
        onPressed: _navigateToPaymentMethods,
        backgroundColor: _nextPaymentDue != null && _isTransactionOverdue(_nextPaymentDue!)
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: Icon(
          _nextPaymentDue != null && _isTransactionOverdue(_nextPaymentDue!)
              ? Icons.priority_high
              : Icons.payment,
          color: Colors.white,
        ),
        label: Text(
          _nextPaymentDue != null && _isTransactionOverdue(_nextPaymentDue!)
              ? 'Pay Now!'
              : 'Pay Now',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: _selectedIndex == 0
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'payment',
              color: _selectedIndex == 1
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'history',
              color: _selectedIndex == 2
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _selectedIndex == 3
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
