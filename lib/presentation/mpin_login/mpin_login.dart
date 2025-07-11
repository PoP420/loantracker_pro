import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../client_dashboard/client_dashboard.dart';
import './widgets/biometric_prompt_widget.dart';
import './widgets/lockout_timer_widget.dart';
import './widgets/pin_input_widget.dart';

const int _mpinLoginLength = 4;

class MpinLoginScreen extends StatefulWidget {
  const MpinLoginScreen({super.key});

  @override
  State<MpinLoginScreen> createState() => _MpinLoginScreenState();
}

class _MpinLoginScreenState extends State<MpinLoginScreen>
    with TickerProviderStateMixin {
  final List<String> _pinDigits = List.filled(_mpinLoginLength, '');
  int _currentPinIndex = 0;
  bool _isLoading = false;
  bool _showBiometricButton = false; // Button visibility, not auto-prompt
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutTimeRemaining = 300; // 5 minutes, make this configurable
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String _apiMobileNumber = "";
  String _displayMobileNumber = "Your Mobile Number";

  final String _apiBaseUrl = 'http://192.168.1.102:5000/api/Auth';
  static const String _mobileNumberKey = 'user_mobile_number';
  static const String _userTypeKey = 'user_type';
  // Key to store if biometric was successfully set up by the user
  static const String _biometricEnabledKey = 'biometric_enabled';

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    // Biometric prompt is usually user-initiated via a button after screen loads
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_showBiometricButton && !_isLockedOut) { // Check if button should be visible
    //     // _showBiometricAuthentication(); // Don't auto-trigger, let user tap button
    //   }
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      setState(() {
        _apiMobileNumber = arguments['apiMobileNumber'] ?? '';
        _displayMobileNumber = _formatDisplayNumber(_apiMobileNumber);
      });
    } else {
      _loadStoredData();
    }
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _apiMobileNumber = prefs.getString(_mobileNumberKey) ?? "";
      _displayMobileNumber = _apiMobileNumber.isNotEmpty
          ? _formatDisplayNumber(_apiMobileNumber)
          : "Your Mobile Number";
      // Show biometric button if it was enabled during setup
      _showBiometricButton = prefs.getBool(_biometricEnabledKey) ?? false;
    });
  }

  String _formatDisplayNumber(String apiNumber) {
    if (apiNumber.length == 10 && apiNumber.startsWith('9')) {
      // Common PH format
      return "+63 ${apiNumber.substring(0, 3)} XXXX ${apiNumber.substring(apiNumber.length - 3)}";
    }
    return apiNumber; // Fallback
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutCountdownTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  void _showBiometricAuthentication() {
    if (!mounted || !_showBiometricButton) {
      return; // Check if biometric button should be active
    }
    showDialog(
      context: context,
      barrierDismissible: true, // User can cancel
      builder: (dialogContext) => BiometricPromptWidget(
        onSuccess: () {
          Navigator.of(dialogContext).pop();
          _handleBiometricSuccess();
        },
        onError: (error) {
          Navigator.of(dialogContext).pop();
          _handleBiometricError(error);
        },
        onCancel: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _handleBiometricSuccess() {
    // Assuming biometric success means we can proceed to dashboard
    // In a real app, this might involve using a biometric-specific token or re-validating
    _navigateToRoleDashboard(null,
        null); // Pass userId and userType if available from a secure source
  }

  void _handleBiometricError(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Biometric authentication error: $error'),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
      ),
    );
  }

  void _onPinDigitPressed(String digit) {
    if (_isLockedOut || _isLoading) return;
    HapticFeedback.lightImpact();
    if (_currentPinIndex < _mpinLoginLength) {
      // Use _mpinLoginLength
      setState(() {
        _pinDigits[_currentPinIndex] = digit;
        _currentPinIndex++;
      });
      if (_currentPinIndex == _mpinLoginLength) {
        // Use _mpinLoginLength
        _validatePin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_isLockedOut || _isLoading) return;
    HapticFeedback.lightImpact();
    if (_currentPinIndex > 0) {
      setState(() {
        _currentPinIndex--;
        _pinDigits[_currentPinIndex] = '';
      });
    }
  }

  Future<void> _validatePin() async {
    if (_apiMobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number not found. Please use "Different Account".')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final enteredPin = _pinDigits.join();
      final mpinAsInt = int.tryParse(enteredPin);

      if (mpinAsInt == null) {
        _handleIncorrectPin("Invalid PIN format.");
        return;
      }

      print('=== MPIN LOGIN REQUEST ===');
      print('Mobile Number: $_apiMobileNumber');
      print('MPIN: $mpinAsInt');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/mpin-login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(<String, dynamic>{
          'mobileNumber': _apiMobileNumber,
          'mpin': mpinAsInt,
        }),
      );

      print('=== MPIN LOGIN RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (mounted) {
        final responseBody = jsonDecode(response.body);
        if (response.statusCode == 200) {
          final int? userId = responseBody['userId'];
          final int? userType = responseBody['userType'];

          print('=== LOGIN SUCCESS ===');
          print('User ID: $userId');
          print('User Type: $userType');

          // Store user details
          final prefs = await SharedPreferences.getInstance();
          if (userId != null) await prefs.setInt('user_id', userId);
          if (userType != null) await prefs.setInt(_userTypeKey, userType);

          _navigateToRoleDashboard(userId, userType);
        } else {
          String message = responseBody['message'] ?? 'Invalid PIN or server error.';
          _handleIncorrectPin(message);
        }
      }
    } catch (e) {
      print('MPIN Login Error: $e');
      if (mounted) {
        _handleIncorrectPin('Network error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleIncorrectPin(String apiMessage) {
    // Parameter added
    if (!mounted) return;
    setState(() {
      _failedAttempts++;
      _currentPinIndex = 0;
      _pinDigits.fillRange(0, _mpinLoginLength, '');
    });

    _shakeController.reset();
    _shakeController.forward();

    if (_failedAttempts >= 3) {
      _triggerLockout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$apiMessage ${3 - _failedAttempts} attempts remaining.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  void _triggerLockout() {
    if (!mounted) return;
    setState(() {
      _isLockedOut = true;
      _lockoutTimeRemaining = 300; // 5 minutes, make this configurable
    });
    _startLockoutTimer();
  }

  Timer? _lockoutCountdownTimer; // Store timer to cancel it
  void _startLockoutTimer() {
    _lockoutCountdownTimer?.cancel(); // Cancel any existing timer
    _lockoutCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutTimeRemaining > 0) {
        setState(() {
          _lockoutTimeRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _failedAttempts = 0;
          _currentPinIndex = 0;
          _pinDigits.fillRange(0, _mpinLoginLength, '');
        });
      }
    });
  }

  void _navigateToRoleDashboard(int? userId, int? userType) {
    if (!mounted) return;

    print('=== NAVIGATION DEBUG ===');
    print('User ID: $userId');
    print('User Type: $userType');

    if (userType == 2) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/collector-dashboard', (route) => false,
          arguments: {'userId': userId, 'userType': userType});
    } else if (userType == 10) {
      // Instead of using arguments, we need to pass the parameters directly
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDashboard(
            userId: userId ?? 0,
            userType: userType ?? 0,
          ),
        ),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine user role.')),
      );
    }
  }

  void _forgotPin() {
    if (!mounted) return;
    // Navigate to OTP verification, potentially passing the mobile number
    // if it's available and the OTP screen can use it.
    Navigator.pushNamed(context, '/otp-verification', arguments: {
      'phoneNumber': _displayMobileNumber, // For display
      'apiMobileNumber': _apiMobileNumber, // For API call
    });
  }

  void _useDifferentAccount() {
    if (!mounted) return;
    // Clear SharedPreferences or any other stored session data if necessary
    // For example, if a token was stored:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('auth_token');
    // await prefs.remove(_mobileNumberKey); // Or keep mobile number for convenience?
    Navigator.pushNamedAndRemoveUntil(
        context, '/mobile-number-authentication', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop(); // Exit app on back press from MPIN login
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 8.h),
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomIconWidget(
                    iconName: 'account_balance', // Or your app logo icon
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 10.w,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Welcome Back',
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  _displayMobileNumber, // Use dynamic display number
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 6.h),
                _isLockedOut
                    ? LockoutTimerWidget(
                        timeRemaining: _lockoutTimeRemaining,
                        onResetViaSms:
                            _forgotPin, // Allow navigating to forgot PIN
                      )
                    : Column(
                        children: [
                          Text(
                            'Enter your $_mpinLoginLength-digit PIN', // Updated for 4 digits
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_shakeAnimation.value, 0),
                                child: PinInputWidget(
                                  pinDigits: _pinDigits,
                                  isLoading: _isLoading,
                                  pinLength: _mpinLoginLength, // Pass pinLength
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 6.h),
                          _buildNumericKeypad(),
                          SizedBox(height: 4.h),
                          if (_showBiometricButton &&
                              !_isLoading &&
                              !_isLockedOut)
                            ElevatedButton.icon(
                              onPressed: _showBiometricAuthentication,
                              icon: CustomIconWidget(
                                iconName: 'fingerprint',
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                size: 20,
                              ),
                              label: const Text('Use Biometric'),
                              style: AppTheme
                                  .lightTheme.elevatedButtonTheme.style
                                  ?.copyWith(
                                backgroundColor: WidgetStateProperty.all(
                                  AppTheme.lightTheme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          SizedBox(
                              height: _showBiometricButton
                                  ? 3.h
                                  : 1.h), // Adjust spacing
                          TextButton(
                            onPressed:
                                _isLoading || _isLockedOut ? null : _forgotPin,
                            child: const Text('Forgot PIN?'),
                          ),
                          SizedBox(height: 2.h),
                          TextButton(
                            onPressed: _isLoading || _isLockedOut
                                ? null
                                : _useDifferentAccount,
                            child: const Text('Use Different Account'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      constraints: BoxConstraints(maxWidth: 80.w),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          SizedBox(height: 2.h),
          // Row 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          SizedBox(height: 2.h),
          // Row 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          SizedBox(height: 2.h),
          // Row 4: empty, 0, backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: 15.w), // Empty space
              _buildKeypadButton('0'),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return GestureDetector(
      onTap: () => _onPinDigitPressed(digit),
      child: Container(
        width: 15.w,
        height: 15.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _onBackspacePressed,
      child: Container(
        width: 15.w,
        height: 15.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'backspace', // Ensure this icon exists
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }
}
