import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../core/app_export.dart';

// lib/widgets/custom_error_widget.dart

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const CustomErrorWidget({
    super.key,
    this.errorDetails,
    this.errorMessage,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get user-friendly error message
    String displayMessage = errorMessage ?? 'Something went wrong';
    String description =
        'We encountered an unexpected error while processing your request.';

    if (errorDetails?.exception != null) {
      final error = errorDetails!.exception;
      displayMessage = _getErrorTitle(error);
      description = ErrorHandler.getUserFriendlyMessage(error);
    }

    return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
            child: Center(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/images/sad_face.svg',
                              height: 42, width: 42),
                          const SizedBox(height: 8),
                          Text(displayMessage,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF262626)),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          SizedBox(
                              child: Text(description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF525252), // neutral-600
                                  ))),
                          const SizedBox(height: 24),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (showRetryButton && onRetry != null) ...[
                                  ElevatedButton.icon(
                                      onPressed: onRetry,
                                      icon: const Icon(Icons.refresh,
                                          size: 18, color: Colors.white),
                                      label: const Text('Retry'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.lightTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)))),
                                  const SizedBox(width: 12),
                                ],
                                ElevatedButton.icon(
                                    onPressed: () {
                                      bool canBeBack =
                                          Navigator.canPop(context);
                                      if (canBeBack) {
                                        Navigator.of(context).pop();
                                      } else {
                                        Navigator.pushNamed(
                                            context, AppRoutes.initial);
                                      }
                                    },
                                    icon: const Icon(Icons.arrow_back,
                                        size: 18, color: Colors.white),
                                    label: const Text('Back'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.lightTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)))),
                              ]),
                        ])))));
  }

  String _getErrorTitle(dynamic error) {
    final category = ErrorHandler.getErrorCategory(error);

    switch (category) {
      case 'empty_collection':
        return 'No Data Found';
      case 'index_out_of_bounds':
        return 'Data Access Error';
      case 'invalid_argument':
        return 'Invalid Input';
      case 'type_error':
        return 'Data Format Error';
      case 'format_error':
        return 'Format Error';
      default:
        return 'Something went wrong';
    }
  }
}
