import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CountryCodeSelectorWidget extends StatelessWidget {
  final String selectedCountryCode;
  final Function(String) onCountryCodeChanged;

  const CountryCodeSelectorWidget({
    super.key,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> countryCodes = [
      {'code': '+63', 'country': 'PH', 'name': 'Philippines'},
      {'code': '+1', 'country': 'US', 'name': 'United States'},
      {'code': '+44', 'country': 'GB', 'name': 'United Kingdom'},
      {'code': '+91', 'country': 'IN', 'name': 'India'},
      {'code': '+86', 'country': 'CN', 'name': 'China'},
    ];

    return GestureDetector(
      onTap: () => _showCountryCodePicker(context, countryCodes),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCountryFlag(selectedCountryCode),
              style: TextStyle(fontSize: 5.w),
            ),
            SizedBox(width: 2.w),
            Text(
              selectedCountryCode,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 1.w),
            CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryFlag(String countryCode) {
    switch (countryCode) {
      case '+63':
        return '🇵🇭';
      case '+1':
        return '🇺🇸';
      case '+44':
        return '🇬🇧';
      case '+91':
        return '🇮🇳';
      case '+86':
        return '🇨🇳';
      default:
        return '🌍';
    }
  }

  void _showCountryCodePicker(
      BuildContext context, List<Map<String, String>> countryCodes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 1.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Country',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 3.h),
            ...countryCodes.map((country) => ListTile(
                  leading: Text(
                    _getCountryFlag(country['code']!),
                    style: TextStyle(fontSize: 6.w),
                  ),
                  title: Text(
                    country['name']!,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: Text(
                    country['code']!,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    onCountryCodeChanged(country['code']!);
                    Navigator.pop(context);
                  },
                )),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
