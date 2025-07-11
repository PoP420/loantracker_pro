import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/app_export.dart';
import './widgets/country_code_selector_widget.dart';
import './widgets/phone_number_input_widget.dart';
import './widgets/send_otp_button_widget.dart';
import './widgets/terms_privacy_widget.dart';

class MobileNumberAuthentication extends StatefulWidget {
  const MobileNumberAuthentication({super.key});

  @override
  State<MobileNumberAuthentication> createState() =>
      _MobileNumberAuthenticationState();
}

class _MobileNumberAuthenticationState
    extends State<MobileNumberAuthentication> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  String _selectedCountryCode = '+63';
  bool _isValidNumber = false;
  bool _isLoading = false;
  String? _errorMessage;

  // TODO: Move to a constants file or environment configuration
  final String _apiBaseUrl = 'http://192.168.1.102:5000/api/Auth';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    setState(() {
      // Assuming PH 10-digit mobile number starting with 9 (e.g., 917xxxxxxx)
      _isValidNumber = phoneNumber.length == 11 && phoneNumber.startsWith('0');
      _errorMessage = null;
    });
  }

  void _onCountryCodeChanged(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
    });
    _validatePhoneNumber(); // Re-validate if country code context changes behavior (not strictly needed here)
  }

  Future<void> _sendOTP() async {
    if (!_isValidNumber || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String mobileNumber =
        _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    // The API expects the 10-digit number for the Philippines.
    // If API expects country code prefix, adjust 'mobileNumberForApi' accordingly.
    final String mobileNumberForApi = mobileNumber;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'mobileNumber': mobileNumberForApi,
        }),
      );

      if (mounted) {
        // Check if the widget is still in the tree
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final userId = responseBody['userId'];
          final userType = responseBody['userType'];
          final requiresMpinSetup = responseBody['requiresMpinSetup'];

          if (requiresMpinSetup) {
            Navigator.pushNamed(
              context,
              '/mpin-setup',
              arguments: {
                'userId': userId,
                'userType': userType,
                'apiMobileNumber': mobileNumberForApi,
              },
            );
          } else {
            Navigator.pushNamed(
              context,
              '/mpin-login',
              arguments: {
                'userId': userId,
                'userType': userType,
                'apiMobileNumber': mobileNumberForApi,
              },
            );
          }
        } else {
          // Handle API errors
          String message = 'Failed to send OTP. Please try again.';
          if (response.body.isNotEmpty) {
            try {
              final responseBody = jsonDecode(response.body);
              message = responseBody['message'] ?? message;
            } catch (e) {
              // Could not parse error message
            }
          }
          setState(() {
            _errorMessage = message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network error. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onBackPressed() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/splash-screen',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _onBackPressed,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 6.w,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 6.h),

                // Company Logo
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'account_balance',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      size: 10.w,
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // Title
                Text(
                  'LoanTracker Pro',
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),

                SizedBox(height: 2.h),

                // Subtitle
                Text(
                  'Enter your mobile number to get started',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 6.h),

                // Phone number input section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Number',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Country code and phone input row
                    Row(
                      children: [
                        // Country code selector
                        CountryCodeSelectorWidget(
                          selectedCountryCode: _selectedCountryCode,
                          onCountryCodeChanged: _onCountryCodeChanged,
                        ),

                        SizedBox(width: 3.w),

                        // Phone number input
                        Expanded(
                          child: PhoneNumberInputWidget(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            isValid: _isValidNumber,
                            hasError: _errorMessage != null,
                            onSubmitted: (_) => _sendOTP(),
                          ),
                        ),
                      ],
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      SizedBox(height: 1.h),
                      Text(
                        _errorMessage!,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ],

                    // Validation hint
                    if (!_isValidNumber &&
                        _phoneController.text.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        'Please enter a valid 11-digit mobile number starting with 09',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 6.h),

                // Send OTP Button
                SendOtpButtonWidget(
                  isEnabled: _isValidNumber && !_isLoading,
                  isLoading: _isLoading,
                  onPressed: _sendOTP,
                ),

                SizedBox(height: 4.h),

                // Terms and Privacy
                TermsPrivacyWidget(),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
