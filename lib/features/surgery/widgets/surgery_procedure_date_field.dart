import 'package:flutter/material.dart';

import '../../../core/calendar/turkish_special_days.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/page_header.dart';

class SurgeryProcedureDateField extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final bool enabled;

  const SurgeryProcedureDateField({
    super.key,
    required this.selectedDate,
    required this.onTap,
    this.enabled = true,
  });

  static String compactDateLabel(DateTime date) {
    return '${date.day} ${TurkishSpecialDays.monthLabel(date.month)} ${date.year} · '
        '${PageHeader.weekdayTr(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = selectedDate == null
        ? 'İşlem tarihi seçin'
        : compactDateLabel(selectedDate!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.smallBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selectedDate == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
