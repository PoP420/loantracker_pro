import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences

import '../../core/app_export.dart';
import './widgets/otp_input_field_widget.dart';
import './widgets/phone_number_display_widget.dart';
import './widgets/resend_timer_widget.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResendingOtp = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String _phoneNumberForDisplay = '';
  String _apiMobileNumber =
      ''; // For API calls (without country code, as per API DTO)

  // TODO: Move to a constants file or environment configuration
  final String _apiBaseUrl = 'http://192.168.1.102:5000/api/Auth';
  static const String _mobileNumberKey =
      'user_mobile_number'; // Key for SharedPreferences
  static const String _userIdKey = 'user_id'; // Key for SharedPreferences
  // static const String _biometricEnabledKey = 'biometric_enabled'; // Key for SharedPreferences (if managing here)

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _setupShakeAnimation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        setState(() {
          _phoneNumberForDisplay = arguments['phoneNumber'] ?? 'N/A';
          _apiMobileNumber = arguments['apiMobileNumber'] ?? '';
        });
      }
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
            HapticFeedback.lightImpact();
          }
        });
      }
    });
  }

  String get _otpCode {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isOtpComplete {
    return _otpCode.length == 6;
  }

  void _onOtpChanged(int index, String value) {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty && index == 5 && _isOtpComplete) {
      _verifyOtp(); // Auto-submit when OTP is complete
    }
  }

  void _onOtpBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {
      // Clear error on backspace as well
      _hasError = false;
      _errorMessage = '';
    });
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _apiMobileNumber.isEmpty) return;

    FocusScope.of(context).unfocus(); // Dismiss keyboard
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/verify-otp'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'mobileNumber': _apiMobileNumber,
          'otp': _otpCode,
        }),
      );

      if (mounted) {
        final responseBody = jsonDecode(response.body);
        if (response.statusCode == 200) {
          final bool requiresMpinSetup =
              responseBody['requiresMpinSetup'] ?? false;
          final int? userId = responseBody['userId'];
          // final String? token = responseBody['token']; // TODO: Handle token if API provides it

          // Save mobile number and userId to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_mobileNumberKey, _apiMobileNumber);
          if (userId != null) {
            await prefs.setInt(_userIdKey, userId);
          }
          // Example: if you want to explicitly set biometric as not enabled yet
          // await prefs.setBool(_biometricEnabledKey, false);

          if (requiresMpinSetup) {
            Navigator.pushReplacementNamed(context, '/mpin-setup', arguments: {
              'apiMobileNumber': _apiMobileNumber,
              'userId': userId,
            });
          } else {
            // Login successful (already has MPIN), navigate to dashboard/home
            // TODO: Replace '/client-dashboard' with your actual home screen route
            Navigator.pushNamedAndRemoveUntil(
                context, '/client-dashboard', (route) => false,
                arguments: {'userId': userId});
          }
        } else {
          String message =
              responseBody['message'] ?? 'Invalid OTP or server error.';
          _showError(message);
          _shakeFields();
          _clearOtpFields();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(
            'Network error. Please check your connection and try again.');
        _shakeFields();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  void _shakeFields() {
    _shakeController.reset();
    _shakeController.forward();
  }

  void _clearOtpFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _apiMobileNumber.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isResendingOtp = true; // Use a separate flag for resend loading state
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(
            '$_apiBaseUrl/login'), // Resend OTP uses the same initial login endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'mobileNumber': _apiMobileNumber,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _startResendTimer();
          _clearOtpFields();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New OTP sent successfully'),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          String message = 'Failed to resend OTP. Please try again.';
          if (response.body.isNotEmpty) {
            try {
              final responseBody = jsonDecode(response.body);
              message = responseBody['message'] ?? message;
            } catch (e) {
              // Could not parse error message
            }
          }
          _showError(message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Network error while resending OTP. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingOtp = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName:
                'arrow_back_ios', // Consider using 'arrow_back' for Material consistency
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // Or .light depending on AppBar color
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Header
              Text(
                'Verify Your Phone',
                style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Enter the 6-digit code sent to',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Phone number display
              PhoneNumberDisplayWidget(
                phoneNumber:
                    _phoneNumberForDisplay, // Use the dynamic phone number
                onEdit: () => Navigator.pop(context), // Go back to edit number
              ),

              const SizedBox(height: 48),

              // OTP Input Fields
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: index == 0 || index == 5 ? 0 : 4,
                            ),
                            child: OtpInputFieldWidget(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              hasError: _hasError,
                              onChanged: (value) => _onOtpChanged(index, value),
                              onBackspace: () => _onOtpBackspace(index),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              if (_hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.error
                          .withOpacity(0.3), // Use withOpacity for consistency
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'error_outline',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Resend Timer
              ResendTimerWidget(
                countdown: _resendCountdown,
                canResend: _canResend,
                isLoading:
                    _isResendingOtp, // Use specific loading state for resend
                onResend: _resendOtp,
              ),

              const SizedBox(height: 48),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isOtpComplete && !_isLoading ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOtpComplete && !_isLoading
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline
                            .withOpacity(0.5), // Dim if disabled
                    foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    elevation: _isOtpComplete && !_isLoading ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.lightTheme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Verify',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isOtpComplete && !_isLoading
                                ? AppTheme.lightTheme.colorScheme.onPrimary
                                : AppTheme.lightTheme.colorScheme.onSurface
                                    .withOpacity(0.7),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Help text
              Text(
                'Didn\'t receive the code? Check your SMS or try resending.',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
