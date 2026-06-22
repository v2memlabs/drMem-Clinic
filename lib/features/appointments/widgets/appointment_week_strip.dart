import 'package:flutter/material.dart';

import '../../../core/calendar/turkish_special_days.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/appointment_calendar_helper.dart';

/// Hafta şeridi — Tip 2 randevu listesi birincil gün navigasyonu.
class AppointmentWeekStrip extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDay;
  final Map<DateTime, int> appointmentCountsByDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback? onPickDate;

  const AppointmentWeekStrip({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.appointmentCountsByDay,
    required this.onDaySelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
    this.onPickDate,
  });

  static String weekRangeLabel(DateTime weekStart) {
    final days = AppointmentCalendarHelper.daysInWeek(weekStart);
    final first = days.first;
    final last = days.last;
    if (first.month == last.month) {
      return '${first.day}–${last.day} ${TurkishSpecialDays.monthLabel(first.month)} ${first.year}';
    }
    return '${first.day} ${TurkishSpecialDays.monthLabel(first.month)} – '
        '${last.day} ${TurkishSpecialDays.monthLabel(last.month)} ${last.year}';
  }

  @override
  Widget build(BuildContext context) {
    final days = AppointmentCalendarHelper.daysInWeek(weekStart);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Önceki hafta',
                    onPressed: onPreviousWeek,
                    icon: const Icon(Icons.chevron_left, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      weekRangeLabel(weekStart),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onPickDate != null)
                    IconButton(
                      tooltip: 'Tarih seç',
                      onPressed: onPickDate,
                      icon: const Icon(Icons.calendar_month_outlined, size: 20),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Sonraki hafta',
                    onPressed: onNextWeek,
                    icon: const Icon(Icons.chevron_right, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: _DayCell(
                      day: day,
                      isSelected: AppointmentCalendarHelper.isSameDay(
                        day,
                        selectedDay,
                      ),
                      isToday: AppointmentCalendarHelper.isToday(day),
                      count: appointmentCountsByDay[
                              AppointmentCalendarHelper.normalize(day)] ??
                          0,
                      onTap: () => onDaySelected(day),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isSelected
        ? AppColors.primaryDeepTeal.withValues(alpha: 0.12)
        : Colors.transparent;
    final border = isSelected
        ? Border.all(color: AppColors.primaryDeepTeal, width: 1.5)
        : isToday
            ? Border.all(color: AppColors.accentTurquoise.withValues(alpha: 0.6))
            : Border.all(color: Colors.transparent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: bg,
        borderRadius: AppRadius.smallBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smallBorder,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.smallBorder,
              border: border,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppointmentCalendarHelper.shortWeekdayLabel(day),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? AppColors.primaryDeepTeal
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
                Text(
                  '${day.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryDeepTeal
                        : AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                _CountBadge(count: count, highlighted: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool highlighted;

  const _CountBadge({required this.count, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox(height: 4, width: 4);
    }

    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryDeepTeal
            : AppColors.accentTurquoise.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlighted ? Colors.white : AppColors.accentTurquoise,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              height: 1,
            ),
      ),
    );
  }
}
