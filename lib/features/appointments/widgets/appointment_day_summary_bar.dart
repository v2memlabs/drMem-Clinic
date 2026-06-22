import 'package:flutter/material.dart';

import '../../../core/calendar/turkish_special_days.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/appointment_calendar_helper.dart';
import '../data/appointment_day_availability_summary.dart';
import '../models/appointment_slot.dart';

/// Seçili gün özeti — randevu sayısı ve müsait slot bilgisi.
class AppointmentDaySummaryBar extends StatelessWidget {
  final DateTime selectedDay;
  final int? appointmentCount;
  final AppointmentAvailabilityResult? availability;
  final bool loadingAvailability;

  const AppointmentDaySummaryBar({
    super.key,
    required this.selectedDay,
    this.appointmentCount,
    this.availability,
    this.loadingAvailability = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = AppointmentCalendarHelper.normalize(selectedDay);
    final isToday = AppointmentCalendarHelper.isToday(day);
    final dateLabel =
        '${day.day} ${TurkishSpecialDays.monthLabel(day.month)} ${day.year}';
    final weekday = PageHeader.weekdayTr(day);

    final headline = isToday
        ? 'Bugün · $weekday · $dateLabel'
        : '$weekday · $dateLabel';

    final parts = <String>[];
    if (appointmentCount == null) {
      parts.add('yükleniyor…');
    } else {
      parts.add('$appointmentCount randevu');
      if (loadingAvailability) {
        parts.add('slotlar yükleniyor…');
      } else {
        final slotLabel =
            AppointmentDayAvailabilitySummary.slotStatsLabel(availability);
        if (slotLabel != null) {
          parts.add(slotLabel);
        }
      }
    }

    final stats = parts.join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            headline,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          stats,
          textAlign: TextAlign.right,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
