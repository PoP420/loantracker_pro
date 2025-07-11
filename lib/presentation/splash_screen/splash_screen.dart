import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import './widgets/background_gradient_widget.dart';
import './widgets/loading_indicator_widget.dart';
import './widgets/logo_animation_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _fadeAnimation;

  bool _isInitializing = true;
  bool _showRetryOption = false;
  String _initializationStatus = 'Initializing...';

  // Mock authentication states
  bool _isAuthenticated = false;
  bool _hasMPINSetup = false;
  String _userRole = '';
  bool _isNewUser = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _logoController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Set status bar style for branding
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

      // Simulate initialization tasks
      await _performInitializationTasks();

      // Wait for minimum splash duration
      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        await _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showRetryOption = true;
          _initializationStatus = 'Initialization failed. Please try again.';
        });
      }
    }
  }

  Future<void> _performInitializationTasks() async {
    // Simulate checking authentication tokens
    setState(() {
      _initializationStatus = 'Checking authentication...';
    });
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock authentication check
    _isAuthenticated = false; // Simulate no authentication
    _hasMPINSetup = false;
    _userRole = '';
    _isNewUser = true;

    // Simulate validating MPIN status
    setState(() {
      _initializationStatus = 'Validating security...';
    });
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate loading user role
    setState(() {
      _initializationStatus = 'Loading user data...';
    });
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate fetching configuration
    setState(() {
      _initializationStatus = 'Fetching configuration...';
    });
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate preparing cached data
    setState(() {
      _initializationStatus = 'Preparing data...';
    });
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _initializationStatus = 'Ready!';
    });
  }

  Future<void> _navigateToNextScreen() async {
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Navigation logic based on authentication status
    String nextRoute;

    if (_isAuthenticated && _hasMPINSetup) {
      // Authenticated users with valid MPIN go to role-specific dashboard
      nextRoute = _userRole == 'collector'
          ? '/collector-dashboard'
          : '/client-dashboard';
    } else if (_isAuthenticated && !_hasMPINSetup) {
      // Users requiring MPIN setup
      nextRoute = '/mpin-setup';
    } else if (_isNewUser) {
      // New users reach mobile number registration
      nextRoute = '/mobile-number-authentication';
    } else {
      // Returning non-authenticated users see login screen
      nextRoute = '/mpin-login';
    }

    Navigator.pushReplacementNamed(context, nextRoute);
  }

  void _retryInitialization() {
    setState(() {
      _isInitializing = true;
      _showRetryOption = false;
      _initializationStatus = 'Retrying...';
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Background gradient
            const BackgroundGradientWidget(),

            // Safe area content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo animation
                          LogoAnimationWidget(
                            scaleAnimation: _logoScaleAnimation,
                            opacityAnimation: _logoOpacityAnimation,
                          ),

                          const SizedBox(height: 48),

                          // Loading indicator or retry option
                          _showRetryOption
                              ? _buildRetrySection()
                              : LoadingIndicatorWidget(
                                  status: _initializationStatus,
                                  isLoading: _isInitializing,
                                ),
                        ],
                      ),
                    ),
                  ),

                  // App version info
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      'LoanTracker Pro v1.0.0',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetrySection() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'error_outline',
          color: Colors.white.withValues(alpha: 0.8),
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          _initializationStatus,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Retry'),
            ],
          ),
        ),
      ],
    );
  }
}
