import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import './widgets/qr_scanner_overlay_widget.dart';
import './widgets/qr_code_display_widget.dart';
import './widgets/gcash_payment_widget.dart';

class GCashPaymentScreen extends StatefulWidget {
  const GCashPaymentScreen({super.key});

  @override
  State<GCashPaymentScreen> createState() => _GCashPaymentScreenState();
}

class _GCashPaymentScreenState extends State<GCashPaymentScreen> {
  bool _showQrScanner = false;
  bool _isFlashlightOn = false;
  Map<String, dynamic> _paymentContext = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentContext();
    });
  }

  void _initializePaymentContext() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _paymentContext = args;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('GCash Payment'),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      ),
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Context Card
                _buildPaymentContextCard(),
                const SizedBox(height: 24),
                
                // Manual Payment Instructions
                _buildManualPaymentCard(),
                const SizedBox(height: 24),
                
                // QR Scanner Option (Optional Enhancement)
                GCashPaymentWidget(
                  onQrScanPressed: () {
                    setState(() {
                      _showQrScanner = true;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Upload Receipt Button
                _buildUploadReceiptButton(),
              ],
            ),
          ),
          
          // QR Scanner Overlay
          if (_showQrScanner)
            QrScannerOverlayWidget(
              isFlashlightOn: _isFlashlightOn,
              onClose: () {
                setState(() {
                  _showQrScanner = false;
                });
              },
              onToggleFlashlight: () {
                setState(() {
                  _isFlashlightOn = !_isFlashlightOn;
                });
              },
              onQrCodeScanned: (qrCode) {
                setState(() {
                  _showQrScanner = false;
                });
                _handleQrCodeScanned(qrCode);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentContextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'payment',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Details',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Amount', '₱${(_paymentContext["amount"] as num?)?.toStringAsFixed(2) ?? "0.00"}'),
          _buildDetailRow('Loan ID', _paymentContext["loanId"]?.toString() ?? "N/A"),
          _buildDetailRow('Due Date', _paymentContext["dueDate"] ?? "N/A"),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Manual Payment Instructions',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Open your GCash app\n'
            '2. Go to "Send Money" or "Pay Bills"\n'
            '3. Enter the merchant details provided\n'
            '4. Send the exact amount: ₱${(_paymentContext["amount"] as num?)?.toStringAsFixed(2) ?? "0.00"}\n'
            '5. Take a screenshot of the confirmation\n'
            '6. Return here and upload the receipt',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadReceiptButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/receipt-upload', arguments: _paymentContext);
        },
        icon: CustomIconWidget(
          iconName: 'upload',
          color: AppTheme.lightTheme.colorScheme.onPrimary,
          size: 20,
        ),
        label: Text(
          'Upload Payment Receipt',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _handleQrCodeScanned(String qrCode) {
    // Handle QR code scanning result
    // For manual approach, this could just show merchant info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Scanned'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('QR Code: $qrCode'),
            const SizedBox(height: 16),
            Text('Please proceed with manual payment in your GCash app, then upload the receipt.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/receipt-upload', arguments: _paymentContext);
            },
            child: Text('Upload Receipt'),
          ),
        ],
      ),
    );
  }
}
