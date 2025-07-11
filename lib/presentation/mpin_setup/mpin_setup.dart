import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/mpin_input_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/security_info_widget.dart';

// MPIN length is 4 digits as per API
const int _mpinLength = 4;

class MpinSetupScreen extends StatefulWidget {
  const MpinSetupScreen({super.key});

  @override
  State<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends State<MpinSetupScreen> {
  final List<TextEditingController> _mpinControllers =
      List.generate(_mpinLength, (index) => TextEditingController());
  final List<TextEditingController> _confirmMpinControllers =
      List.generate(_mpinLength, (index) => TextEditingController());
  final List<FocusNode> _mpinFocusNodes =
      List.generate(_mpinLength, (index) => FocusNode());
  final List<FocusNode> _confirmMpinFocusNodes =
      List.generate(_mpinLength, (index) => FocusNode());

  String _mpin = '';
  String _confirmMpin = '';
  bool _isMatching = false;
  bool _isValidPin = true; // Default to true, validated on full entry
  String _errorMessage = '';
  bool _isLoading = false;

  String _apiMobileNumber = '';
  int? _userId; // UserId might be needed by API or for subsequent steps
  int? _userType;

  // TODO: Move to a constants file or environment configuration
  final String _apiBaseUrl = 'http://192.168.1.102:5000/api/Auth';
  static const String _mobileNumberKey = 'user_mobile_number';
  static const String _userIdKey = 'user_id';
  static const String _biometricEnabledKey = 'biometric_enabled';

  @override
  void initState() {
    super.initState();
    _setupControllerListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        setState(() {
          _apiMobileNumber = arguments['apiMobileNumber'] ?? '';
          _userId = arguments['userId']; // Can be null if not provided
          _userType = arguments['userType'];
        });
      }
      if (_mpinFocusNodes.isNotEmpty) {
        _mpinFocusNodes[0].requestFocus();
      }
    });
  }

  void _setupControllerListeners() {
    for (int i = 0; i < _mpinLength; i++) {
      _mpinControllers[i].addListener(() => _updateMpin());
      _confirmMpinControllers[i].addListener(() => _updateConfirmMpin());
    }
  }

  void _updateMpin() {
    setState(() {
      _mpin = _mpinControllers.map((controller) => controller.text).join();
      _validateAndCheckMatch();
    });
  }

  void _updateConfirmMpin() {
    setState(() {
      _confirmMpin =
          _confirmMpinControllers.map((controller) => controller.text).join();
      _validateAndCheckMatch();
    });
  }

  void _validateAndCheckMatch() {
    // Clear previous errors first
    _errorMessage = '';
    _isValidPin = true;

    if (_mpin.length == _mpinLength) {
      _isValidPin = _validatePinStrength(_mpin);
      if (!_isValidPin) {
        _errorMessage = 'Weak PIN. Avoid sequential or repeated digits.';
      }
    }

    if (_mpin.length == _mpinLength && _confirmMpin.length == _mpinLength) {
      if (_mpin != _confirmMpin) {
        _errorMessage = 'PINs do not match. Please try again.';
        _isMatching = false;
      } else if (!_isValidPin) {
        // Error message for weak PIN already set
        _isMatching = false;
      } else {
        // PINs match and PIN is valid
        _isMatching = true;
        _errorMessage = ''; // Clear any previous error
      }
    } else {
      _isMatching = false;
    }
  }

  bool _validatePinStrength(String pin) {
    if (pin.length != _mpinLength) {
      return true; // Don't validate incomplete PINs
    }

    // Check for sequential numbers (e.g., 1234, 4321)
    bool isAscending = true;
    bool isDescending = true;
    for (int i = 0; i < pin.length - 1; i++) {
      if (int.parse(pin[i + 1]) != int.parse(pin[i]) + 1) isAscending = false;
      if (int.parse(pin[i + 1]) != int.parse(pin[i]) - 1) isDescending = false;
    }
    if (isAscending || isDescending) return false;

    // Check for all same digits (e.g., 1111, 8888)
    if (pin.split('').every((digit) => digit == pin[0])) return false;

    // Add more checks if needed, e.g., common patterns like '1212', '0000'
    // For a 4-digit PIN, '0000', '1111', ... '9999' are covered by "all same digits"
    // '1234', '2345', ... are covered by "sequential"
    // Common patterns like '1212', '1313' could be added
    List<String> commonPatterns = [
      '0000',
      '1111',
      '2222',
      '3333',
      '4444',
      '5555',
      '6666',
      '7777',
      '8888',
      '9999',
      '1234',
      '2345',
      '3456',
      '4567',
      '5678',
      '6789',
      '9876',
      '8765',
      '7654',
      '6543',
      '5432',
      '4321'
    ];
    if (commonPatterns.contains(pin)) return false;

    return true;
  }

  void _onDigitEntered(int index, String value, bool isConfirm) {
    if (value.isNotEmpty) {
      HapticFeedback.lightImpact();
      if (index < _mpinLength - 1) {
        if (isConfirm) {
          _confirmMpinFocusNodes[index + 1].requestFocus();
        } else {
          _mpinFocusNodes[index + 1].requestFocus();
        }
      } else {
        // Last digit entered
        if (isConfirm) {
          _confirmMpinFocusNodes[index].unfocus();
          if (_isMatching) _createMpin(); // Auto-submit if valid and matching
        } else {
          _mpinFocusNodes[index].unfocus();
          if (_mpin.length == _mpinLength && _isValidPin) {
            // Only move if current PIN is valid
            _confirmMpinFocusNodes[0].requestFocus();
          }
        }
      }
    }
  }

  void _onBackspace(int index, bool isConfirm) {
    // Always clear the current field on backspace if it's not empty
    if (isConfirm) {
      if (_confirmMpinControllers[index].text.isNotEmpty) {
        _confirmMpinControllers[index].clear();
      } else if (index > 0) {
        _confirmMpinFocusNodes[index - 1].requestFocus();
        _confirmMpinControllers[index - 1]
            .clear(); // Clear previous field as well
      }
    } else {
      if (_mpinControllers[index].text.isNotEmpty) {
        _mpinControllers[index].clear();
      } else if (index > 0) {
        _mpinFocusNodes[index - 1].requestFocus();
        _mpinControllers[index - 1].clear(); // Clear previous field as well
      }
    }
    _validateAndCheckMatch(); // Re-validate after backspace
  }

  Future<void> _createMpin() async {
    if (!_isMatching ||
        _mpin.length != _mpinLength ||
        _apiMobileNumber.isEmpty) {
      if (_mpin.length == _mpinLength &&
          _confirmMpin.length == _mpinLength &&
          !_isMatching) {
        _errorMessage = 'PINs do not match or are invalid.';
      } else if (_mpin.length != _mpinLength ||
          _confirmMpin.length != _mpinLength) {
        _errorMessage = 'Please complete both MPIN fields.';
      }
      setState(() {}); // Update UI with error message
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Clear previous errors
    });

    try {
      final mpinAsInt = int.tryParse(_mpin);
      if (mpinAsInt == null) {
        throw Exception("MPIN is not a valid number");
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/create-mpin'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          // API expects mpin as int
          'mobileNumber': _apiMobileNumber,
          'mpin': mpinAsInt,
        }),
      );

      if (mounted) {
        final responseBody = jsonDecode(response.body);
        if (response.statusCode == 200) {
          // MPIN created successfully
          final int? newUserId = responseBody['userId'];
          final int? newUserType = responseBody['userType'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_mobileNumberKey, _apiMobileNumber);
          if (newUserId != null) {
            await prefs.setInt(_userIdKey, newUserId);
          } else if (_userId != null) {
            await prefs.setInt(_userIdKey, _userId!);
          }
          if (newUserType != null) {
            await prefs.setInt('user_type', newUserType);
          } else if (_userType != null) {
            await prefs.setInt('user_type', _userType!);
          }
          // Biometric preference will be set in the dialog's callbacks

          _showBiometricEnrollmentDialog(
              newUserId ?? _userId,
              newUserType ??
                  _userType); // Pass userId and userType to biometric dialog
        } else {
          String message = responseBody['message'] ??
              'Failed to create MPIN. Please try again.';
          setState(() {
            _errorMessage = message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _showBiometricEnrollmentDialog(
      int? currentUserId, int? currentUserType) {
    if (!mounted) return; // Ensure widget is still mounted
    showDialog(
      context: context, // This context should be from the build method scope
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use a different name for dialog's context
        return AlertDialog(
          title: Text(
            'Enable Biometric Authentication?',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Would you like to enable fingerprint or face authentication for faster access?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Use dialogContext to pop
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(
                    _biometricEnabledKey, false); // User skipped biometric
                _navigateToNextScreen(
                    currentUserId, currentUserType); // Pass currentUserId
              },
              child: Text(
                'Skip',
                style:
                    TextStyle(color: AppTheme.lightTheme.colorScheme.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Use dialogContext to pop
                // TODO: Implement actual biometric enrollment logic here
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(
                    _biometricEnabledKey, true); // User enabled biometric
                _navigateToNextScreen(
                    currentUserId, currentUserType); // Pass currentUserId
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Redundant showDialog block was already removed in the file content provided by user.

  void _navigateToNextScreen(int? currentUserId, int? currentUserType) {
    if (!mounted) return;

    if (currentUserType == 2) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/collector-dashboard', (route) => false,
          arguments: {'userId': currentUserId});
    } else if (currentUserType == 10) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/client-dashboard', (route) => false,
          arguments: {'userId': currentUserId});
    } else {
      // Fallback to a default or error screen
      Navigator.pushNamedAndRemoveUntil(
          context, '/client-dashboard', (route) => false,
          arguments: {'userId': currentUserId});
    }
  }

  void _clearAllPins() {
    for (var controller in _mpinControllers) {
      controller.clear();
    }
    for (var controller in _confirmMpinControllers) {
      controller.clear();
    }
    setState(() {
      _mpin = '';
      _confirmMpin = '';
      _isMatching = false;
      _isValidPin = true; // Reset validation state
      _errorMessage = '';
      if (_mpinFocusNodes.isNotEmpty) {
        _mpinFocusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _mpinControllers) {
      controller.dispose();
    }
    for (var controller in _confirmMpinControllers) {
      controller.dispose();
    }
    for (var focusNode in _mpinFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _confirmMpinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress Indicator
              ProgressIndicatorWidget(
                  currentStep: 2, totalSteps: 3), // Current: MPIN Setup

              SizedBox(height: 4.h),

              // Header Section
              Column(
                children: [
                  CustomIconWidget(
                    iconName: 'security', // Or 'pin' / 'lock'
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 64,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Create Your MPIN',
                    style:
                        AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    // Updated text for 4-digit MPIN
                    'Set up a secure $_mpinLength-digit PIN for quick and safe access to your loan account.',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              SizedBox(height: 4.h),

              // Security Info (ensure this widget is generic enough or update if needed)
              SecurityInfoWidget(),

              SizedBox(height: 4.h),

              // MPIN Input Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter $_mpinLength-digit MPIN',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  MpinInputWidget(
                    // This widget needs to be adapted for _mpinLength
                    controllers: _mpinControllers,
                    focusNodes: _mpinFocusNodes,
                    pinLength: _mpinLength, // Pass the length to the widget
                    onDigitEntered: (index, value) =>
                        _onDigitEntered(index, value, false),
                    onBackspace: (index) => _onBackspace(index, false),
                    isError: _mpin.length == _mpinLength &&
                        !_isValidPin &&
                        _errorMessage.isNotEmpty,
                  ),
                ],
              ),

              SizedBox(height: 4.h),

              // Confirm MPIN Input Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Confirm $_mpinLength-digit MPIN',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      if (_isMatching &&
                          _mpin.length == _mpinLength &&
                          _confirmMpin.length == _mpinLength &&
                          _isValidPin) ...[
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.lightTheme.colorScheme
                              .tertiary, // Or a success color
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  MpinInputWidget(
                    // This widget needs to be adapted for _mpinLength
                    controllers: _confirmMpinControllers,
                    focusNodes: _confirmMpinFocusNodes,
                    pinLength: _mpinLength, // Pass the length to the widget
                    onDigitEntered: (index, value) =>
                        _onDigitEntered(index, value, true),
                    onBackspace: (index) => _onBackspace(index, true),
                    isError: _confirmMpin.length == _mpinLength &&
                        !_isMatching &&
                        _errorMessage.isNotEmpty,
                    isEnabled: _mpin.length == _mpinLength &&
                        _isValidPin, // Enable only if first PIN is valid and complete
                  ),
                ],
              ),

              // Error Message
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.errorContainer
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.error
                              .withOpacity(0.3))),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'error_outline',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            // Changed from bodySmall for better visibility
                            color: AppTheme.lightTheme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 6.h),

              // Create MPIN Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isMatching && _isValidPin && !_isLoading
                      ? _createMpin
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    backgroundColor: (_isMatching && _isValidPin && !_isLoading)
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline
                            .withOpacity(0.5),
                    foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.lightTheme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Create MPIN',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: (_isMatching && _isValidPin && !_isLoading)
                                ? AppTheme.lightTheme.colorScheme.onPrimary
                                : AppTheme.lightTheme.colorScheme.onSurface
                                    .withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 3.h),

              // Back Button (Consider its behavior carefully)
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        // Navigating back might require passing original arguments if OTP screen expects them
                        // For simplicity, just pop or navigate to a known safe state.
                        // If OTP screen was pushed with arguments, popping might be okay.
                        // If it was pushReplacementNamed, then need to navigate explicitly.
                        _clearAllPins();
                        // This assumes OtpVerificationScreen can handle being pushed without arguments
                        // or that the necessary arguments are re-fetched or handled gracefully.
                        // A better approach might be to pass back the original mobile number.
                        Navigator.pushReplacementNamed(
                            context, '/otp-verification',
                            arguments: {
                              'phoneNumber':
                                  '', // This might be an issue, OTP screen expects a display number
                              'apiMobileNumber':
                                  _apiMobileNumber, // Pass back the apiMobileNumber
                            });
                      },
                child: Text(
                  'Back', // Simpler text
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
