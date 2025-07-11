import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../model.dart';
import '../../loan_history/loan_history_screen.dart';

class AssignedLoanCardWidget extends StatelessWidget {
  final AssignedLoanMdl loan;
  final VoidCallback onCall;
  final VoidCallback onPayment;
  final VoidCallback onVisited;
  final VoidCallback onNotes;
  final VoidCallback onSkip;
  final int collectorId;

  const AssignedLoanCardWidget({
    super.key,
    required this.loan,
    required this.onCall,
    required this.onPayment,
    required this.onVisited,
    required this.onNotes,
    required this.onSkip,
    required this.collectorId,
  });

  Color _getStatusColor() {
    switch (loan.loan?.status) {
      case 'Completed':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'Overdue':
        return AppTheme.lightTheme.colorScheme.error;
      case 'Pending':
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getStatusText() {
    switch (loan.loan?.status) {
      case 'Completed':
        return 'Completed';
      case 'Overdue':
        return 'Overdue';
      case 'Pending':
      default:
        return 'Pending';
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final phoneNumber = loan.client?.userName; // userName contains mobile number
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        // Clean the phone number (remove any non-digit characters except +)
        String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

        // Try different URL schemes for better compatibility
        final List<String> phoneSchemes = [
          'tel:$cleanNumber',
          'tel://$cleanNumber',
        ];

        bool launched = false;
        for (String scheme in phoneSchemes) {
          try {
            final Uri phoneUri = Uri.parse(scheme);
            if (await canLaunchUrl(phoneUri)) {
              await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
              launched = true;
              HapticFeedback.mediumImpact();
              break;
            }
          } catch (e) {
            print('Failed to launch $scheme: $e');
            continue;
          }
        }

        if (!launched) {
          // Fallback: Show the phone number in a dialog
          _showPhoneNumberDialog(context);
        }
      } catch (e) {
        print('Error launching phone dialer: $e');
        _showPhoneNumberDialog(context);
      }
    } else {
      _showPhoneNumberDialog(context);
    }
  }

  void _showPhoneNumberDialog(BuildContext context) {
    final phoneNumber = loan.client?.userName ?? 'No phone number available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${loan.client?.fullName ?? 'Client'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Phone Number:'),
            SizedBox(height: 8),
            SelectableText(
              phoneNumber,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Tap and hold to copy the number, then use your phone app to call.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (phoneNumber != 'No phone number available')
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Phone number copied to clipboard')),
                );
              },
              child: Text('Copy'),
            ),
        ],
      ),
    );
  }

  void _navigateToLoanHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanHistoryScreen(
          loan: loan,
          collectorId: collectorId,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(loan.client?.fullName ?? '',
                  style: AppTheme.lightTheme.textTheme.titleMedium),
              const SizedBox(height: 16),
              _buildMenuOption(context, 'View Loan Details', 'assignment', () {
                Navigator.pop(context);
                // Navigate to loan details
              }),
              _buildMenuOption(context, 'Transaction History', 'history', () {
                Navigator.pop(context);
                _navigateToLoanHistory(context);
              }),
              _buildMenuOption(context, 'Client Profile', 'person', () {
                Navigator.pop(context);
                // Navigate to client profile
              }),
              _buildMenuOption(context, 'Call Client', 'phone', () {
                Navigator.pop(context);
                _makePhoneCall(context);
              }),
              const SizedBox(height: 16),
            ])));
  }

  Widget _buildMenuOption(
      BuildContext context, String title, String icon, VoidCallback onTap) {
    return ListTile(
        leading: CustomIconWidget(
            iconName: icon,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24),
        title: Text(title),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: Key(loan.loan!.loanId.toString()),
        background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.tertiary,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              CustomIconWidget(
                  iconName: 'phone',
                  color: AppTheme.lightTheme.colorScheme.onTertiary,
                  size: 24),
              const SizedBox(width: 8),
              Text('Call',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onTertiary)),
              const Spacer(),
              CustomIconWidget(
                  iconName: 'check',
                  color: AppTheme.lightTheme.colorScheme.onTertiary,
                  size: 24),
              const SizedBox(width: 8),
              Text('Visited',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onTertiary)),
            ])),
        secondaryBackground: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.error,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.centerRight,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('Skip Today',
                  style: AppTheme.lightTheme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white)),
              const SizedBox(width: 8),
              CustomIconWidget(
                  iconName: 'skip_next', color: Colors.white, size: 24),
            ])),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Right swipe - Quick actions
            _showQuickActions(context);
            return false;
          } else {
            // Left swipe - Skip today
            onSkip();
            return false;
          }
        },
        child: GestureDetector(
            onLongPress: () => _showContextMenu(context),
            child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.shadow
                              .withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with client info and status
                      Row(children: [
                        CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                            child: CustomIconWidget(
                              iconName: 'person',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 24,
                            )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loan.client?.fullName ?? '',
                                      style: AppTheme
                                          .lightTheme.textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text('ID: ${loan.loan?.loanId} • ${loan.client?.userName ?? 'No phone'}',
                                      style:
                                      AppTheme.lightTheme.textTheme.bodySmall),
                                ])),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: _getStatusColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(_getStatusText(),
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                    color: _getStatusColor(),
                                    fontWeight: FontWeight.w500))),
                      ]),
                      const SizedBox(height: 16),
                      // Loan details
                      Row(children: [
                        Expanded(
                            child: _buildDetailItem(
                                'Loan Amount',
                                '₱${loan.loan?.amount?.toStringAsFixed(2) ?? '0.00'}',
                                'account_balance')),
                        Expanded(
                            child: _buildDetailItem(
                                'Outstanding',
                                '₱${loan.loan?.total?.toStringAsFixed(2) ?? '0.00'}',
                                'trending_up')),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _buildDetailItem(
                                'Interest',
                                '₱${loan.loan?.interest?.toStringAsFixed(2) ?? '0.00'}',
                                'percent')),
                        Expanded(
                            child: _buildDetailItem(
                                'Term',
                                '${loan.loan?.loanTerm ?? 0} months',
                                'schedule')),
                      ]),
                      const SizedBox(height: 16),
                      // Action buttons - Updated to remove location and add history
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () => _makePhoneCall(context),
                                icon: CustomIconWidget(
                                    iconName: 'phone',
                                    color:
                                    AppTheme.lightTheme.colorScheme.primary,
                                    size: 18),
                                label: const Text('Call'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () => _navigateToLoanHistory(context),
                                icon: CustomIconWidget(
                                    iconName: 'history',
                                    color:
                                    AppTheme.lightTheme.colorScheme.primary,
                                    size: 18),
                                label: const Text('History'))),
                        const SizedBox(width: 8),
                      //  Expanded(
                      //      child: ElevatedButton.icon(
                      //          onPressed: onPayment,
                      //          icon: CustomIconWidget(
                      //              iconName: 'payment',
                      //              color: AppTheme
                      //                  .lightTheme.colorScheme.onPrimary,
                      //              size: 18),
                      //          label: const Text('Pay'))),
                      ]),
                    ]))));
  }

  Widget _buildDetailItem(String label, String value, String icon) {
    return Row(children: [
      CustomIconWidget(
          iconName: icon,
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 16),
      const SizedBox(width: 8),
      Expanded(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: AppTheme.lightTheme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(value,
                style: AppTheme.lightTheme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ])),
    ]);
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Quick Actions',
                  style: AppTheme.lightTheme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildQuickActionButton(context, 'Call Client', 'phone',
                    AppTheme.lightTheme.colorScheme.tertiary, () => _makePhoneCall(context)),
                _buildQuickActionButton(context, 'Mark Visited', 'check_circle',
                    AppTheme.lightTheme.colorScheme.tertiary, onVisited),
                _buildQuickActionButton(context, 'Record Payment', 'payment',
                    AppTheme.lightTheme.colorScheme.primary, onPayment),
                _buildQuickActionButton(context, 'View History', 'history',
                    AppTheme.lightTheme.colorScheme.secondary, () => _navigateToLoanHistory(context)),
              ]),
              const SizedBox(height: 16),
            ])));
  }

  Widget _buildQuickActionButton(BuildContext context, String label,
      String icon, Color color, VoidCallback onTap) {
    return GestureDetector(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Column(children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Center(
                  child: CustomIconWidget(
                      iconName: icon, color: color, size: 24))),
          const SizedBox(height: 8),
          Text(label,
              style: AppTheme.lightTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]));
  }
}
