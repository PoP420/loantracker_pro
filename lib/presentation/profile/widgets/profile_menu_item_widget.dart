import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

// lib/presentation/profile/widgets/profile_menu_item_widget.dart

class ProfileMenuItemWidget extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const ProfileMenuItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(8)),
                  child: CustomIconWidget(
                      iconName: icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ])),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else if (showArrow && onTap != null) ...[
                const SizedBox(width: 12),
                CustomIconWidget(
                    iconName: 'chevron_right',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20),
              ],
            ])));
  }
}
