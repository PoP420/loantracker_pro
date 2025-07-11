import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

// lib/presentation/statement_of_account/widgets/transaction_timeline_widget.dart

class TransactionTimelineWidget extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final Function(Map<String, dynamic>) onTransactionTap;

  const TransactionTimelineWidget({
    super.key,
    required this.transactions,
    required this.onTransactionTap,
  });

  @override
  State<TransactionTimelineWidget> createState() =>
      _TransactionTimelineWidgetState();
}

class _TransactionTimelineWidgetState extends State<TransactionTimelineWidget> {
  final Set<String> _expandedMonths = {};

  Map<String, List<Map<String, dynamic>>> get groupedTransactions {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final transaction in widget.transactions) {
      final date = DateTime.parse(transaction['date']);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(transaction);
    }

    // Sort transactions within each month by date (newest first)
    for (final monthTransactions in grouped.values) {
      monthTransactions.sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Transaction History',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600))),
          ...groupedTransactions.entries.map(
              (entry) => _buildMonthSection(context, entry.key, entry.value)),
        ]));
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          CustomIconWidget(
              iconName: 'receipt_long',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48),
          const SizedBox(height: 16),
          Text('No Transactions Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Try adjusting your filter settings to see more results.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ]));
  }

  Widget _buildMonthSection(BuildContext context, String monthKey,
      List<Map<String, dynamic>> transactions) {
    final date = DateTime.parse('$monthKey-01');
    final monthName = _getMonthName(date.month);
    final year = date.year;
    final isExpanded = _expandedMonths.contains(monthKey);

    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, 1)),
            ]),
        child: Column(children: [
          InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedMonths.remove(monthKey);
                  } else {
                    _expandedMonths.add(monthKey);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(26),
                            borderRadius: BorderRadius.circular(8)),
                        child: CustomIconWidget(
                            iconName: 'calendar_month',
                            color: Theme.of(context).colorScheme.primary,
                            size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('$monthName $year',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                              '${transactions.length} transaction${transactions.length == 1 ? '' : 's'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                        ])),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ]))),
          if (isExpanded) ..._buildTransactionList(context, transactions),
        ]));
  }

  List<Widget> _buildTransactionList(
      BuildContext context, List<Map<String, dynamic>> transactions) {
    return transactions
        .map((transaction) => _buildTransactionItem(context, transaction))
        .toList();
  }

  Widget _buildTransactionItem(
      BuildContext context, Map<String, dynamic> transaction) {
    final isCredit = transaction['creditAmount'] > 0;
    final amount =
        isCredit ? transaction['creditAmount'] : transaction['debitAmount'];
    final color = _getTransactionColor(context, transaction['type']);

    return InkWell(
        onTap: () => widget.onTransactionTap(transaction),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(51),
                        width: 0.5))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(8)),
                  child: CustomIconWidget(
                      iconName: _getTransactionIcon(transaction['type']),
                      color: color,
                      size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(transaction['description'],
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(_formatDate(transaction['date']),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                      if (transaction['reference'] != null) ...[
                        const SizedBox(width: 8),
                        Text('•',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Text(transaction['reference'],
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ],
                    ]),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${isCredit ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text('₱${transaction['runningBalance'].toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ])));
  }

  Color _getTransactionColor(BuildContext context, String type) {
    switch (type) {
      case 'payment':
        return Theme.of(context).colorScheme.tertiary;
      case 'interest':
      case 'fee':
        return Theme.of(context).colorScheme.error;
      case 'adjustment':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getTransactionIcon(String type) {
    switch (type) {
      case 'payment':
        return 'payments';
      case 'interest':
        return 'trending_up';
      case 'fee':
        return 'receipt_long';
      case 'adjustment':
        return 'tune';
      default:
        return 'receipt';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
