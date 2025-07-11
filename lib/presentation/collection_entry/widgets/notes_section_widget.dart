import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotesSectionWidget extends StatelessWidget {
  final TextEditingController notesController;
  final FocusNode notesFocusNode;
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const NotesSectionWidget({
    super.key,
    required this.notesController,
    required this.notesFocusNode,
    required this.isExpanded,
    required this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onExpandToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'note_add',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add Notes',
                      style:
                      AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CustomIconWidget(
                    iconName: isExpanded ? 'expand_less' : 'expand_more',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (!isExpanded)
            Text(
              'Tap to add visit details, client circumstances, or collection notes',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (isExpanded) ...[
            SizedBox(height: 2.h),
            TextFormField(
              controller: notesController,
              focusNode: notesFocusNode,
              maxLines: 4,
              maxLength: 500,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText:
                'Enter visit details, client circumstances, or collection challenges...',
                hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.all(4.w),
                counterStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Quick note buttons
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                _buildQuickNoteChip('Client not home'),
                _buildQuickNoteChip('Promised to pay tomorrow'),
                _buildQuickNoteChip('Partial payment made'),
                _buildQuickNoteChip('Financial difficulty'),
                _buildQuickNoteChip('Requested extension'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickNoteChip(String text) {
    return InkWell(
      onTap: () {
        if (notesController.text.isNotEmpty) {
          notesController.text += ', $text';
        } else {
          notesController.text = text;
        }
        notesController.selection = TextSelection.fromPosition(
          TextPosition(offset: notesController.text.length),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.primary,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
