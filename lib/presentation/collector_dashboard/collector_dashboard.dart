// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../model.dart';
import '../../api_service.dart';
import '../../model/transaction.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../collector_repayment_schedule/repayment_schedule.dart';
import './widgets/assigned_loan_card_widget.dart';
import './widgets/collection_stats_widget.dart';
import './widgets/progress_ring_widget.dart';
import '../collection_entry/collection_entry.dart';
import '../loan_history/loan_history_screen.dart';

class CollectorDashboard extends StatefulWidget {
  final int userId;
  final int userType;

  const CollectorDashboard(
      {super.key, required this.userId, required this.userType});

  @override
  State<CollectorDashboard> createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  // API and Data State
  final ApiService _apiService = ApiService();
  List<AssignedLoanMdl> _assignedLoans = [];
  final Map<int, List<Transaction>> _transactions = {};
  String? _errorMessage;

  Map<String, dynamic> _collectionStats = {
    "todaysTarget": "\$15,000.00",
    "todaysAchieved": "\$0.00",
    "progressPercentage": 0.0,
    "todaysCollections": "\$0.00",
    "pendingVisits": 0,
    "completedPayments": 0,
    "outstandingAmount": "\$0.00"
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAssignedLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssignedLoans() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.1.102:5000/api/Collector/${widget.userId}/assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        // Handle the response as a List directly
        if (responseData is List) {
          setState(() {
            _assignedLoans = responseData.map((data) {
              return _parseAssignedLoan(data);
            }).where((loan) => loan != null).cast<AssignedLoanMdl>().toList();
          });
        } else if (responseData is Map && responseData['Data'] != null) {
          // Handle wrapped response format
          final List<dynamic> dataList = responseData['Data'] as List<dynamic>;
          setState(() {
            _assignedLoans = dataList.map((data) {
              return _parseAssignedLoan(data);
            }).where((loan) => loan != null).cast<AssignedLoanMdl>().toList();
          });
        } else {
          // Handle empty response or unexpected format
          setState(() {
            _assignedLoans = [];
          });
        }

        // Calculate stats from loaded data
        _calculateStats();

        // Fetch transactions for each loan
        _fetchTransactionsForLoans();

      } else if (response.statusCode == 404) {
        setState(() {
          _assignedLoans = [];
          _errorMessage = null; // Don't show error for no assignments
        });
      } else {
        setState(() {
          _errorMessage =
          'Failed to load assigned loans: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
      });
      print('Error fetching assigned loans: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  AssignedLoanMdl? _parseAssignedLoan(dynamic data) {
    try {
      // Handle the actual API response structure (lowercase keys)
      final loanData = data['loan']; // lowercase 'loan'
      final clientData = data['client']; // lowercase 'client'

      if (loanData == null || clientData == null) {
        print('Missing loan or client data: $data');
        return null;
      }

      return AssignedLoanMdl(
        loan: LoanMdl(
          loanId: _safeParseInt(loanData['loanId']),
          userId: _safeParseInt(loanData['userId']),
          amount: _safeParseDouble(loanData['amount']),
          interest: _safeParseDouble(loanData['interest']),
          total: _safeParseDouble(loanData['total']),
          loanTerm: _safeParseInt(loanData['loanTerm']),
          status: _safeParseString(loanData['status']),
          loanTypeID: _safeParseInt(loanData['loanTypeID']),
        ),
        client: UserMdl(
          userId: _safeParseInt(clientData['userId']),
          userName: _safeParseString(clientData['userName']),
          fullName: _safeParseString(clientData['fullName']),
          pin: _safeParseString(clientData['pin']),
          address: _safeParseString(clientData['address']),
        ),
      );
    } catch (e) {
      print('Error parsing loan data: $e');
      print('Data: $data');
      return null;
    }
  }

  // Safe parsing helper methods
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _safeParseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  void _calculateStats() {
    if (_assignedLoans.isEmpty) {
      setState(() {
        _collectionStats = {
          "todaysTarget": "\$15,000.00",
          "todaysAchieved": "\$0.00",
          "progressPercentage": 0.0,
          "todaysCollections": "\$0.00",
          "pendingVisits": 0,
          "completedPayments": 0,
          "outstandingAmount": "\$0.00"
        };
      });
      return;
    }

    double totalOutstanding = 0;
    int pendingVisits = _assignedLoans.length;

    for (var loan in _assignedLoans) {
      totalOutstanding += loan.loan?.total ?? 0;
    }

    setState(() {
      _collectionStats = {
        "todaysTarget": "\$15,000.00",
        "todaysAchieved": "\$0.00", // This would come from today's payments
        "progressPercentage": 0.0, // Calculate based on actual collections
        "todaysCollections": "\$0.00",
        "pendingVisits": pendingVisits,
        "completedPayments": 0,
        "outstandingAmount": "\$${totalOutstanding.toStringAsFixed(2)}"
      };
    });
  }

  Future<void> _refreshData() async {
    await _fetchAssignedLoans();
  }

  Future<void> _fetchTransactionsForLoans() async {
    for (var loan in _assignedLoans) {
      if (loan.loan?.loanId != null) {
        try {
          final response = await http.get(
            Uri.parse(
                'http://192.168.1.8:5000/api/Collector/${widget.userId}/assignments/${loan.loan!.loanId}/transactions'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> transactionsData = jsonDecode(response.body);
            final transactions = transactionsData.map((data) {
              return _parseTransaction(data);
            }).where((t) => t != null).cast<Transaction>().toList();

            setState(() {
              _transactions[loan.loan!.loanId!] = transactions;
            });
          }
        } catch (e) {
          print(
              'Error fetching transactions for loan ${loan.loan!.loanId}: $e');
        }
      }
    }
  }

  Transaction? _parseTransaction(dynamic data) {
    try {
      return Transaction(
        id: _safeParseInt(data['id']) ?? 0,
        loanId: _safeParseInt(data['loanID']) ?? 0,
        principalDue: _safeParseDouble(data['principalDue']) ?? 0.0,
        interestDue: _safeParseDouble(data['interestDue']) ?? 0.0,
        penaltiesDue: _safeParseDouble(data['penaltiesDue']) ?? 0.0,
        totalDue: _safeParseDouble(data['totalDue']) ?? 0.0,
        weeklyDue: _safeParseDouble(data['weeklyDue']) ?? 0.0,
        serviceFeesDue: _safeParseDouble(data['serviceFeesDue']) ?? 0.0,
        dueDate: DateTime.tryParse(data['dueDate']?.toString() ?? '') ?? DateTime.now(),
        monthlyDueDate: DateTime.tryParse(data['monthlyDueDate']?.toString() ?? '') ?? DateTime.now(),
        isPaid: data['isPaid'] == true,
        remarks: _safeParseString(data['remarks']),
        penaltyMonthsApplied: _safeParseInt(data['penaltyMonthsApplied']) ?? 0,
      );
    } catch (e) {
      print('Error parsing transaction data: $e');
      return null;
    }
  }

  List<AssignedLoanMdl> get _filteredLoans {
    if (_searchQuery.isEmpty) {
      return _assignedLoans;
    }

    return _assignedLoans.where((loan) {
      final clientName = loan.client?.fullName?.toLowerCase() ?? '';
      final loanId = loan.loan?.loanId?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return clientName.contains(query) || loanId.contains(query);
    }).toList();
  }

  void _makePhoneCall(String? phoneNumber) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${phoneNumber ?? 'client'}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openMaps(String? address) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${address ?? 'client location'}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _recordPaymentFromCard(AssignedLoanMdl loan) {
    // Navigate to collection entry screen with loan data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionEntry(
          loan: loan,
          collectorId: widget.userId,
        ),
      ),
    ).then((_) {
      // Refresh data when returning from collection entry
      _refreshData();
    });
  }

  void _markAsVisited(AssignedLoanMdl loan) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${loan.client?.fullName ?? 'Client'} marked as visited'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addNotes(AssignedLoanMdl loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Notes for ${loan.client?.fullName ?? 'Client'}'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter your notes here...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notes saved successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _skipToday(AssignedLoanMdl loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip ${loan.client?.fullName ?? 'Client'} Today'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select reason for skipping:'),
            const SizedBox(height: 16),
            ...[
              'Client not available',
              'Bad weather',
              'Emergency',
              'Other'
            ].map((reason) => ListTile(
              title: Text(reason),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                    Text('${loan.client?.fullName ?? 'Client'} skipped: $reason'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              // Sticky Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.shadow
                          .withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with date and progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Collections',
                              style: AppTheme.lightTheme.textTheme.titleMedium,
                            ),
                            Text(
                              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        ProgressRingWidget(
                          progress:
                          _collectionStats["progressPercentage"] as double,
                          target: _collectionStats["todaysTarget"] as String,
                          achieved:
                          _collectionStats["todaysAchieved"] as String,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by client name or loan ID...',
                        prefixIcon: CustomIconWidget(
                          iconName: 'search',
                          color:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick Stats Cards
              CollectionStatsWidget(stats: _collectionStats),
              // Error Message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: _refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              // Assigned Loans List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredLoans.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredLoans.length,
                  itemBuilder: (context, index) {
                    final loan = _filteredLoans[index];
                    final loanTransactions =
                        _transactions[loan.loan?.loanId] ?? [];

                    return Column(
                      children: [
                        AssignedLoanCardWidget(
                          loan: loan,
                          collectorId: widget.userId, // Add this line
                          onCall: () =>
                              _makePhoneCall(loan.client?.userName),
                          onPayment: () => _recordPaymentFromCard(loan),
                          onVisited: () => _markAsVisited(loan),
                          onNotes: () => _addNotes(loan),
                          onSkip: () => _skipToday(loan),
                        ),
                        // Show transactions if available
                        if (loanTransactions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoanHistoryScreen(
                                      loan: loan,
                                      collectorId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                              icon: CustomIconWidget(
                                iconName: 'history',
                                color: AppTheme.lightTheme.colorScheme.onPrimary,
                                size: 20,
                              ),
                              label: Text('View Transaction History (${loanTransactions.length})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                                foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on Collections tab
              break;
            case 1:
            // Navigate to Loans tab - show all loans with history
              if (_assignedLoans.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanHistoryScreen(
                      loan: _assignedLoans.first, // Or create a loans list screen
                      collectorId: widget.userId,
                    ),
                  ),
                );
              }
              break;
        //    case 2:
        //      Navigator.pushNamed(context, '/monthly-reports');
        //      break;
        //    case 3:
            // Navigate to Profile tab (placeholder)
        //      break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'account_balance_wallet',
              color: AppTheme
                  .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
              size: 24,
            ),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'assignment',
              color: AppTheme
                  .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Loans',
          ),
        //  BottomNavigationBarItem(
        //    icon: CustomIconWidget(
       //       iconName: 'bar_chart',
       //       color: AppTheme
       //           .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
       //       size: 24,
        //    ),
       //     label: 'Reports',
       //   ),
       //   BottomNavigationBarItem(
       //     icon: CustomIconWidget(
        //      iconName: 'person',
        //      color: AppTheme
       //           .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
        //      size: 24,
        //    ),
        //    label: 'Profile',
        //  ),
        ],
      ),
      // collector_dashboard.dart (update floatingActionButton)
      floatingActionButton: _assignedLoans.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepaymentSchedule(
                loan: _assignedLoans.first, // Or implement multi-loan selection
                collectorId: widget.userId,
              ),
            ),
          ).then((_) => _refreshData());
        },
        icon: CustomIconWidget(
          iconName: 'add',
          color: AppTheme.lightTheme.floatingActionButtonTheme.foregroundColor!,
          size: 24,
        ),
        label: const Text('Quick Entry'),
      )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'assignment_turned_in',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No loans found for "$_searchQuery"'
                  : 'No loans assigned yet',
              style: AppTheme.lightTheme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Check back later for new assignments or contact your supervisor.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
