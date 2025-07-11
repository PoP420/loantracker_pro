import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../core/utils/error_handler.dart';
import './custom_error_widget.dart';

// lib/widgets/error_boundary_widget.dart

/// Error boundary widget to catch and handle errors in widget trees
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final VoidCallback? onError;
  final bool showErrorDetails;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
    this.showErrorDetails = false,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = details;
        });
        widget.onError?.call();
      }

      // Still report to the original error handler
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
  }

  void _resetError() {
    setState(() {
      _hasError = false;
      _errorDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          CustomErrorWidget(
            errorDetails: _errorDetails,
            onRetry: _resetError,
            showRetryButton: true,
          );
    }

    return ErrorBoundary(
      onError: (error, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorDetails = FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'error_boundary',
              context: ErrorDescription('Error caught by ErrorBoundaryWidget'),
            );
          });
          widget.onError?.call();
        }
      },
      child: widget.child,
    );
  }
}

/// A widget that catches errors in its child widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Wrap in error handling
    ErrorHandler.handleError(
      () {
        super.didChangeDependencies();
      },
      silent: true,
    );
  }
}
