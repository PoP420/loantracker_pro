import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import './widgets/image_preview_widget.dart';
import './widgets/upload_button_widget.dart';
import './widgets/upload_progress_widget.dart';

class ReceiptUploadScreen extends StatefulWidget {
  const ReceiptUploadScreen({super.key});

  @override
  State<ReceiptUploadScreen> createState() => _ReceiptUploadScreenState();
}

class _ReceiptUploadScreenState extends State<ReceiptUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  bool _uploadSuccess = false;
  String? _referenceNumber;

  // Payment context from navigation arguments
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
        _paymentContext = {
          "transactionId": args['transactionId']?.toString() ?? "TXN-${DateTime.now().millisecondsSinceEpoch}",
          "amount": "₱${(args['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
          "loanId": args['loanId']?.toString() ?? "Unknown",
          "dueDate": args['dueDate'] ?? "N/A",
          "paymentMethod": args['paymentMethod'] ?? "GCash",
          "userId": args['userId'],
          "userType": args['userType'],
        };
      });

      print('=== RECEIPT UPLOAD INIT ===');
      print('Payment Context: $_paymentContext');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _uploadSuccess ? _buildSuccessView() : _buildUploadView(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Receipt',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Payment: ${_paymentContext["amount"] ?? "₱0.00"}',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        if (_selectedImages.isNotEmpty && !_isUploading)
          TextButton(
            onPressed: _clearAllImages,
            child: Text(
              'Clear All',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUploadView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentContextCard(),
          const SizedBox(height: 24),
          _buildInstructionsCard(),
          const SizedBox(height: 24),
          if (_selectedImages.isNotEmpty) ...[
            _buildSelectedImagesSection(),
            const SizedBox(height: 24),
          ],
          if (_isUploading) ...[
            UploadProgressWidget(
              progress: _uploadProgress,
              onCancel: _cancelUpload,
            ),
            const SizedBox(height: 24),
          ],
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 16),
          ],
          _buildUploadButtons(),
          const SizedBox(height: 24),
          _buildImageRequirements(),
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
                iconName: 'receipt_long',
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
          _buildDetailRow('Transaction ID', _paymentContext["transactionId"] ?? "N/A"),
          _buildDetailRow('Loan ID', _paymentContext["loanId"] ?? "N/A"),
          _buildDetailRow('Amount', _paymentContext["amount"] ?? "₱0.00"),
          _buildDetailRow('Due Date', _paymentContext["dueDate"] ?? "N/A"),
          _buildDetailRow('Payment Method', _paymentContext["paymentMethod"] ?? "GCash"),
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
          Flexible(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer
            .withValues(alpha: 0.1),
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
                'Upload Instructions',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Take a clear photo of your ${_paymentContext["paymentMethod"] ?? "payment"} receipt\n'
                '• Ensure all text is readable and not blurred\n'
                '• Include the full receipt in the frame\n'
                '• Make sure the amount and transaction details are visible\n'
                '• You can upload up to 3 images per transaction',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Images (${_selectedImages.length}/3)',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_selectedImages.isNotEmpty && !_isUploading)
              ElevatedButton(
                onPressed: _uploadImages,
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(80, 36),
                ),
                child: Text('Upload All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ImagePreviewWidget(
                imageFile: _selectedImages[index],
                onRemove: () => _removeImage(index),
                onEdit: () => _editImage(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButtons() {
    final bool canAddMore = _selectedImages.length < 3;

    return Column(
      children: [
        if (canAddMore) ...[
          UploadButtonWidget(
            title: 'Take Photo',
            subtitle: 'Use camera to capture receipt',
            icon: 'camera_alt',
            isPrimary: true,
            onPressed:
            _isUploading ? null : () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          UploadButtonWidget(
            title: 'Choose from Gallery',
            subtitle: 'Select from photo library',
            icon: 'photo_library',
            isPrimary: false,
            onPressed:
            _isUploading ? null : () => _pickImage(ImageSource.gallery),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Maximum images selected',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can upload up to 3 images per transaction',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageRequirements() {
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
          Text(
            'Image Requirements',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirementItem('Minimum resolution: 720x720 pixels'),
          _buildRequirementItem('Maximum file size: 5MB per image'),
          _buildRequirementItem('Supported formats: JPG, PNG'),
          _buildRequirementItem('Text must be clearly readable'),
          _buildRequirementItem('No blurred or dark images'),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: 'check',
            color: AppTheme.lightTheme.colorScheme.tertiary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.errorContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.tertiary
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Receipt Uploaded Successfully!',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.tertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your payment receipt has been submitted for verification. You will receive a confirmation once processed.',
            style: AppTheme.lightTheme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Reference Number',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _referenceNumber ??
                      'REF-${DateTime.now().millisecondsSinceEpoch}',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/payment-history', arguments: {
                      'userId': _paymentContext['userId'],
                      'userType': _paymentContext['userType'],
                      'loanId': _paymentContext['loanId'],
                    });
                  },
                  child: Text('View History'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Validate image
        if (await _validateImage(imageFile)) {
          setState(() {
            _selectedImages.add(imageFile);
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image. Please try again.';
      });
    }
  }

  Future<bool> _validateImage(File imageFile) async {
    try {
      // Check file size (5MB limit)
      final int fileSizeInBytes = await imageFile.length();
      const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB

      if (fileSizeInBytes > maxSizeInBytes) {
        setState(() {
          _errorMessage =
          'Image size too large. Please select an image under 5MB.';
        });
        return false;
      }

      // Additional validation can be added here
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate image. Please try again.';
      });
      return false;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _editImage(int index) {
    // Implement image editing functionality
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image editing feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
      _errorMessage = null;
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100;
          });
        }
      }

      // Simulate successful upload
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _uploadSuccess = true;
          _referenceNumber = 'REF-${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage =
          'Upload failed. Please check your connection and try again.';
        });
      }
    }
  }

  void _cancelUpload() {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }
}
