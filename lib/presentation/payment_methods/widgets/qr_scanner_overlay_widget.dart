import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class QrScannerOverlayWidget extends StatefulWidget {
  final bool isFlashlightOn;
  final VoidCallback onClose;
  final VoidCallback onToggleFlashlight;
  final Function(String) onQrCodeScanned;

  const QrScannerOverlayWidget({
    super.key,
    required this.isFlashlightOn,
    required this.onClose,
    required this.onToggleFlashlight,
    required this.onQrCodeScanned,
  });

  @override
  State<QrScannerOverlayWidget> createState() => _QrScannerOverlayWidgetState();
}

class _QrScannerOverlayWidgetState extends State<QrScannerOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  final TextEditingController _manualCodeController = TextEditingController();
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    _scanLineController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _simulateQrScan() {
    // Mock QR code scanning - simulate successful scan after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onQrCodeScanned('GCASH_QR_CODE_SAMPLE_123456789');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: SafeArea(
        child: Stack(
          children: [
            // Camera Preview Simulation
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Corner indicators
                      ...List.generate(
                          4, (index) => _buildCornerIndicator(index)),

                      // Scanning line animation
                      AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: _scanLineAnimation.value * 260 + 10,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.lightTheme.colorScheme.primary,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Tap to scan simulation
                      GestureDetector(
                        onTap: _simulateQrScan,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.transparent,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIconWidget(
                                  iconName: 'qr_code_scanner',
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to simulate scan',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close Button
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Flashlight Button
                  GestureDetector(
                    onTap: widget.onToggleFlashlight,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isFlashlightOn
                            ? AppTheme.lightTheme.colorScheme.primary
                            : Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CustomIconWidget(
                        iconName:
                            widget.isFlashlightOn ? 'flash_on' : 'flash_off',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Scan QR Code',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Position the QR code within the frame to scan',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Manual Entry Toggle
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showManualEntry = !_showManualEntry;
                      });
                    },
                    icon: CustomIconWidget(
                      iconName: 'keyboard',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      _showManualEntry
                          ? 'Hide Manual Entry'
                          : 'Enter Code Manually',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  // Manual Entry Field
                  if (_showManualEntry) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _manualCodeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter QR code manually',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_manualCodeController.text.isNotEmpty) {
                                  widget.onQrCodeScanned(
                                      _manualCodeController.text);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppTheme.lightTheme.colorScheme.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Submit Code'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(int index) {
    final positions = [
      {'top': 8.0, 'left': 8.0}, // Top-left
      {'top': 8.0, 'right': 8.0}, // Top-right
      {'bottom': 8.0, 'left': 8.0}, // Bottom-left
      {'bottom': 8.0, 'right': 8.0}, // Bottom-right
    ];

    final position = positions[index];

    return Positioned(
      top: position['top'],
      left: position['left'],
      right: position['right'],
      bottom: position['bottom'],
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: index < 2
                ? BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary, width: 3)
                : BorderSide.none,
            bottom: index >= 2
                ? BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary, width: 3)
                : BorderSide.none,
            left: index % 2 == 0
                ? BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary, width: 3)
                : BorderSide.none,
            right: index % 2 == 1
                ? BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
