import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/statement_service.dart';
import './widgets/account_summary_card_widget.dart';
import './widgets/period_selector_widget.dart';
import './widgets/statement_filter_widget.dart';
import './widgets/statement_header_widget.dart';
import './widgets/transaction_timeline_widget.dart';

class StatementOfAccountScreen extends StatefulWidget {
  final int userId;
  final int? initialLoanId;

  const StatementOfAccountScreen({
    super.key,
    required this.userId,
    this.initialLoanId,
  });

  @override
  State<StatementOfAccountScreen> createState() =>
      _StatementOfAccountScreenState();
}

class _StatementOfAccountScreenState extends State<StatementOfAccountScreen>
    with TickerProviderStateMixin {
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _isFilterVisible = false;
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedTransactionType = 'all';
  double _minAmount = 0.0;
  double _maxAmount = 100000.0;

  // Data from API
  List<Map<String, dynamic>> _accountInfo = [];
  Map<String, dynamic> _accountSummary = {};
  List<Map<String, dynamic>> _transactions = [];
  int? _selectedLoanId;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedLoanId = widget.initialLoanId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load account info first
      final accountInfo = await StatementService.getAccountInfo(widget.userId);

      if (accountInfo.isNotEmpty) {
        setState(() {
          _accountInfo = accountInfo;
          // Use provided loanId or default to first loan
          _selectedLoanId ??= accountInfo.first['loanId'] as int?;
        });

        if (_selectedLoanId != null) {
          await _loadStatementData();
        }
      } else {
        setState(() {
          _errorMessage = 'No active loans found for this user.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading account data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatementData() async {
    if (_selectedLoanId == null) return;

    try {
      // Load summary and transactions in parallel
      final futures = await Future.wait([
        StatementService.getAccountSummary(
          userId: widget.userId,
          loanId: _selectedLoanId!,
          startDate: _startDate,
          endDate: _endDate,
        ),
        StatementService.getTransactions(
          userId: widget.userId,
          loanId: _selectedLoanId!,
          startDate: _startDate,
          endDate: _endDate,
          transactionType: _selectedTransactionType,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
        ),
      ]);

      setState(() {
        _accountSummary = futures[0] as Map<String, dynamic>;
        _transactions = futures[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading statement data: $e';
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    await _loadStatementData();

    setState(() {
      _isRefreshing = false;
    });

    HapticFeedback.selectionClick();
  }

  void _filterTransactionsByPeriod() {
    switch (_selectedPeriod) {
      case 'monthly':
        _startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case 'quarterly':
        _startDate = DateTime.now().subtract(const Duration(days: 90));
        break;
      case 'yearly':
        _startDate = DateTime.now().subtract(const Duration(days: 365));
        break;
    }
    _endDate = DateTime.now();
    _loadStatementData();
  }

  void _showFilterOptions() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  void _exportStatement() async {
    if (_selectedLoanId == null) return;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Export Statement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'picture_as_pdf',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'Download PDF',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                _generatePDF();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _generatePDF() async {
    if (_selectedLoanId == null) return;

    try {
      final pdfBytes = await StatementService.exportStatementPdf(
        userId: widget.userId,
        loanId: _selectedLoanId!,
        startDate: _startDate,
        endDate: _endDate,
        transactionType: _selectedTransactionType,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
      );

      // Handle PDF download/sharing here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF generated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Statement of Account'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Statement of Account'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedAccount = _accountInfo.isNotEmpty ? _accountInfo.first : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Statement of Account'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: _isFilterVisible
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _exportStatement,
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              if (selectedAccount != null)
                SliverToBoxAdapter(
                  child: StatementHeaderWidget(
                    accountNumber: selectedAccount['accountNumber'] ?? '',
                    accountStatus: selectedAccount['accountStatus'] ?? '',
                    clientName: selectedAccount['clientName'] ?? '',
                    lastUpdated: selectedAccount['lastUpdated']?.toString() ?? '',
                  ),
                ),
              SliverToBoxAdapter(
                child: PeriodSelectorWidget(
                  selectedPeriod: _selectedPeriod,
                  startDate: _startDate,
                  endDate: _endDate,
                  onPeriodChanged: (period) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _filterTransactionsByPeriod();
                  },
                  onDateRangeChanged: (start, end) {
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                      _selectedPeriod = 'custom';
                    });
                    _loadStatementData();
                  },
                ),
              ),
              if (_isFilterVisible)
                SliverToBoxAdapter(
                  child: StatementFilterWidget(
                    selectedTransactionType: _selectedTransactionType,
                    minAmount: _minAmount,
                    maxAmount: _maxAmount,
                    onTransactionTypeChanged: (type) {
                      setState(() {
                        _selectedTransactionType = type;
                      });
                      _loadStatementData();
                    },
                    onAmountRangeChanged: (min, max) {
                      setState(() {
                        _minAmount = min;
                        _maxAmount = max;
                      });
                      _loadStatementData();
                    },
                  ),
                ),
              if (_accountSummary.isNotEmpty)
                SliverToBoxAdapter(
                  child: AccountSummaryCardWidget(
                    openingBalance: (_accountSummary['openingBalance'] ?? 0.0).toDouble(),
                    totalPayments: (_accountSummary['totalPayments'] ?? 0.0).toDouble(),
                    interestCharges: (_accountSummary['interestCharges'] ?? 0.0).toDouble(),
                    feesApplied: (_accountSummary['feesApplied'] ?? 0.0).toDouble(),
                    currentBalance: (_accountSummary['currentBalance'] ?? 0.0).toDouble(),
                  ),
                ),
              SliverToBoxAdapter(
                child: TransactionTimelineWidget(
                  transactions: _transactions,
                  onTransactionTap: (transaction) {
                    _showTransactionDetails(transaction);
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Date', transaction['date']?.toString() ?? ''),
            _buildDetailRow('Description', transaction['description']?.toString() ?? ''),
            _buildDetailRow('Reference', transaction['reference']?.toString() ?? ''),
            if (transaction['paymentMethod'] != null)
              _buildDetailRow('Payment Method', transaction['paymentMethod'].toString()),
            _buildDetailRow('Amount',
                '₱${(transaction['creditAmount'] > 0 ? transaction['creditAmount'] : transaction['debitAmount']).toStringAsFixed(2)}'),
            if ((transaction['principalAmount'] ?? 0) > 0)
              _buildDetailRow('Principal',
                  '₱${transaction['principalAmount'].toStringAsFixed(2)}'),
            if ((transaction['interestAmount'] ?? 0) > 0)
              _buildDetailRow('Interest',
                  '₱${transaction['interestAmount'].toStringAsFixed(2)}'),
            _buildDetailRow('Running Balance',
                '₱${transaction['runningBalance'].toStringAsFixed(2)}'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
