import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/otp_verification/otp_verification.dart';
import '../presentation/mpin_setup/mpin_setup.dart';
import '../presentation/mpin_login/mpin_login.dart';
import '../presentation/mobile_number_authentication/mobile_number_authentication.dart';
import '../presentation/client_dashboard/client_dashboard.dart';
import '../presentation/receipt_upload/receipt_upload.dart';
import '../presentation/payment_history/payment_history.dart';
import '../presentation/repayment_schedule/repayment_schedule.dart';
import '../presentation/collector_dashboard/collector_dashboard.dart';
import '../presentation/payment_methods/payment_methods.dart';
import '../presentation/payment_methods/payment_method_selection_screen.dart';
import '../presentation/monthly_reports/monthly_reports.dart';
import '../presentation/collection_entry/collection_entry.dart';
import '../presentation/statement_of_account/statement_of_account.dart'; // Updated import
import '../presentation/profile/profile.dart';
import '../presentation/payment_methods/gcash_payment_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String mobileNumberAuthentication = '/mobile-number-authentication';
  static const String otpVerification = '/otp-verification';
  static const String mpinSetup = '/mpin-setup';
  static const String mpinLogin = '/mpin-login';
  static const String clientDashboard = '/client-dashboard';
  static const String paymentMethods = '/payment-methods';
  static const String paymentHistory = '/payment-history';
  static const String receiptUpload = '/receipt-upload';
  static const String collectorDashboard = '/collector-dashboard';
  static const String collectionEntry = '/collection-entry';
  static const String monthlyReports = '/monthly-reports';
  static const String statementOfAccount = '/statement-of-account';
  static const String profile = '/profile';
  static const String gcashPayment = '/gcash-payment';
  static const String login = '/login';
  static const String userProfile = '/userProfile';
  static const String repaymentSchedule = '/repayment-schedule';
  static const String gcashPaymentScreen = '/gcash_payment_screen'; // New route

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    mobileNumberAuthentication: (context) => const MobileNumberAuthentication(),
    otpVerification: (context) => const OtpVerificationScreen(),
    mpinSetup: (context) => const MpinSetupScreen(),
    mpinLogin: (context) => const MpinLoginScreen(),


    clientDashboard: (context) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as int? ?? 0;
      final userType = args?['userType'] as int? ?? 0;
      return ClientDashboard(userId: userId, userType: userType);
    },
    paymentMethods: (context) => const PaymentMethodSelectionScreen(),
    gcashPayment:  (context) => const PaymentMethodsScreen(),
    paymentHistory: (context) => const PaymentHistoryScreen(),
    receiptUpload: (context) => const ReceiptUploadScreen(),
    repaymentSchedule: (context) => const RepaymentScheduleScreen(),

    collectorDashboard: (context) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as int? ?? 0;
      final userType = args?['userType'] as int? ?? 0;
      return CollectorDashboard(userId: userId, userType: userType);
    },
    collectionEntry: (context) => const CollectionEntry(),
    monthlyReports: (context) => const MonthlyReportsScreen(),
    gcashPaymentScreen: (context) => const PaymentMethodsScreen(),


    // FIXED: StatementOfAccountScreen with proper parameter handling
    statementOfAccount: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as int?;
      final initialLoanId = args?['initialLoanId'] as int?;

      // Handle missing userId - redirect to error or login
      if (userId == null || userId == 0) {
        return const _MissingUserIdScreen();
      }

      return StatementOfAccountScreen(
        userId: userId,
        initialLoanId: initialLoanId,
      );
    },

    profile: (context) => const ProfileScreen(),
  };

  // Helper method to navigate to statement screen with parameters
  static void navigateToStatementOfAccount(
      BuildContext context, {
        required int userId,
        int? initialLoanId,
      }) {
    Navigator.pushNamed(
      context,
      statementOfAccount,
      arguments: {
        'userId': userId,
        'initialLoanId': initialLoanId,
      },
    );
  }

  // Helper method to navigate to client dashboard with parameters
  static void navigateToClientDashboard(
      BuildContext context, {
        required int userId,
        required int userType,
      }) {
    Navigator.pushNamed(
      context,
      clientDashboard,
      arguments: {
        'userId': userId,
        'userType': userType,
      },
    );
  }

  // Helper method to navigate to collector dashboard with parameters
  static void navigateToCollectorDashboard(
      BuildContext context, {
        required int userId,
        required int userType,
      }) {
    Navigator.pushNamed(
      context,
      collectorDashboard,
      arguments: {
        'userId': userId,
        'userType': userType,
      },
    );
  }
}

// Helper screen for when userId is missing
class _MissingUserIdScreen extends StatelessWidget {
  const _MissingUserIdScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Required'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to be logged in to view your statement of account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to login/authentication
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.mobileNumberAuthentication,
                        (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
