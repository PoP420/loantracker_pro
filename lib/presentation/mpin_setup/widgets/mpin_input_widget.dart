import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MpinInputWidget extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final Function(int index, String value) onDigitEntered;
  final Function(int index) onBackspace;
  final bool isError;
  final bool isEnabled;
  final int pinLength; // Added pinLength parameter

  const MpinInputWidget({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onDigitEntered,
    required this.onBackspace,
    this.isError = false,
    this.isEnabled = true,
    this.pinLength = 6, // Default to 6 if not provided, but we'll pass 4
  });

  @override
  Widget build(BuildContext context) {
    // Ensure controllers and focusNodes match pinLength
    if (controllers.length != pinLength || focusNodes.length != pinLength) {
      // This is a developer error, should not happen if parent widget is correctly configured
      return Text('Error: Controller/FocusNode length mismatch with pinLength.',
          style: TextStyle(color: Colors.red));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(pinLength, (index) {
        // Use pinLength here
        return Container(
          width: pinLength == 4 ? 15.w : 12.w, // Adjust width for 4 digits
          height: pinLength == 4 ? 15.w : 12.w, // Adjust height for 4 digits
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isError
                  ? AppTheme.lightTheme.colorScheme.error
                  : controllers[index].text.isNotEmpty
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
              width: 2,
            ),
            color: controllers[index].text.isNotEmpty
                ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
                : AppTheme.lightTheme.colorScheme.surface,
          ),
          child: Center(
            child: controllers[index].text.isNotEmpty
                ? Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isError
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.primary,
                    ),
                  )
                : TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    enabled: isEnabled,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 0,
                      color: Colors.transparent,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        onDigitEntered(index, value);
                      } else if (value.isEmpty && index > 0) {
                        onBackspace(index);
                      }
                    },
                    onTap: () {
                      // Clear the field when tapped for better UX
                      controllers[index].clear();
                    },
                  ),
          ),
        );
      }),
    );
  }
}
