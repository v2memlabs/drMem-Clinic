import 'package:flutter/material.dart';

import '../../core/calendar/turkish_special_days.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

Future<void> showHolidayCalendarSheet(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _HolidayCalendarSheet(
      initialDate: initialDate ?? DateTime.now(),
    ),
  );
}

class _HolidayCalendarSheet extends StatefulWidget {
  final DateTime initialDate;

  const _HolidayCalendarSheet({required this.initialDate});

  @override
  State<_HolidayCalendarSheet> createState() => _HolidayCalendarSheetState();
}

class _HolidayCalendarSheetState extends State<_HolidayCalendarSheet> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<DateTime?> _monthCells() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = <DateTime?>[];
    for (var i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final monthDays = TurkishSpecialDays.forMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final selectedSpecial = TurkishSpecialDays.onDate(_selectedDay);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Takvim',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${TurkishSpecialDays.monthLabel(_visibleMonth.month)} ${_visibleMonth.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final label in _weekdays)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: _monthCells().length,
              itemBuilder: (context, index) {
                final day = _monthCells()[index];
                if (day == null) return const SizedBox.shrink();

                final specials = TurkishSpecialDays.onDate(day);
                final isSelected = day == _selectedDay;
                final isToday = day ==
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    );

                return InkWell(
                  onTap: () => setState(() => _selectedDay = day),
                  borderRadius: AppRadius.mediumBorder,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryDeepTeal.withValues(alpha: 0.14)
                          : null,
                      borderRadius: AppRadius.mediumBorder,
                      border: isToday
                          ? Border.all(color: AppColors.primaryDeepTeal)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                        ),
                        if (specials.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final s in specials.take(3))
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: TurkishSpecialDays.categoryColor(
                                      s.category,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: SpecialDayCategory.values.map((c) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: TurkishSpecialDays.categoryColor(c),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TurkishSpecialDays.categoryLabel(c),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (selectedSpecial.isNotEmpty) ...[
              Text(
                '${_selectedDay.day} ${TurkishSpecialDays.monthLabel(_selectedDay.month)} ${_selectedDay.year}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final s in selectedSpecial)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.event,
                    color: TurkishSpecialDays.categoryColor(s.category),
                  ),
                  title: Text(s.title),
                  subtitle: Text(TurkishSpecialDays.categoryLabel(s.category)),
                ),
            ] else
              Text(
                'Seçili günde özel gün yok.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            if (monthDays.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bu ay',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in monthDays)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          Icons.circle,
                          size: 10,
                          color: TurkishSpecialDays.categoryColor(s.category),
                        ),
                        title: Text(s.title),
                        trailing: Text(
                          '${s.date.day} ${TurkishSpecialDays.monthLabel(s.date.month)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
