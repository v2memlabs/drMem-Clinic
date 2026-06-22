import 'package:flutter/material.dart';

import '../../../core/calendar/turkish_special_days.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinical_notice.dart';
import '../../../shared/widgets/clinical_notice_tone.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/appointment_availability_data_source.dart';
import '../models/appointment_slot.dart';
import '../models/clinic_schedule_config.dart';

/// Randevu tarih + müsait saat slot seçimi (üst form kartının parçası).
class AppointmentScheduleSection extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? selectedSlotStart;
  final ValueChanged<DateTime?> onSlotSelected;
  final String? excludeAppointmentId;
  final DateTime? preserveCurrentSlotStart;
  final int? preserveCurrentDurationMinutes;
  final bool isEditMode;
  final bool enabled;

  const AppointmentScheduleSection({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.selectedSlotStart,
    required this.onSlotSelected,
    this.excludeAppointmentId,
    this.preserveCurrentSlotStart,
    this.preserveCurrentDurationMinutes,
    this.isEditMode = false,
    this.enabled = true,
  });

  /// Responsive sütun — slot sayısı klinik ayarına göre değişir.
  @visibleForTesting
  static int gridColumnCount(double maxWidth) {
    if (maxWidth < 400) return 4;
    if (maxWidth < 560) return 5;
    if (maxWidth < 720) return 6;
    if (maxWidth < 900) return 7;
    return 8;
  }

  @override
  State<AppointmentScheduleSection> createState() =>
      _AppointmentScheduleSectionState();
}

class _AppointmentScheduleSectionState extends State<AppointmentScheduleSection> {
  ClinicScheduleConfig? _config;
  Future<AppointmentAvailabilityResult>? _slotsFuture;
  String? _dateNotSelectableMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _reloadSlots();
  }

  @override
  void didUpdateWidget(AppointmentScheduleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.excludeAppointmentId != widget.excludeAppointmentId ||
        oldWidget.selectedSlotStart != widget.selectedSlotStart ||
        oldWidget.preserveCurrentSlotStart != widget.preserveCurrentSlotStart) {
      _reloadSlots();
    }
  }

  Future<void> _loadConfig() async {
    final config = await AppointmentAvailabilityDataSource.loadScheduleConfig();
    if (mounted) setState(() => _config = config);
  }

  void _reloadSlots() {
    setState(() {
      _dateNotSelectableMessage = null;
      _slotsFuture = AppointmentAvailabilityDataSource.loadSlotsForDay(
        day: widget.selectedDate,
        excludeAppointmentId: widget.excludeAppointmentId,
        selectedSlotStart: widget.selectedSlotStart,
        preserveCurrentSlotStart: widget.preserveCurrentSlotStart,
        preserveCurrentDurationMinutes: widget.preserveCurrentDurationMinutes,
        isEditMode: widget.isEditMode,
      );
    });
  }

  static String compactDateLabel(DateTime d) {
    return '${d.day} ${TurkishSpecialDays.monthLabel(d.month)} ${d.year} · '
        '${PageHeader.weekdayTr(d)}';
  }

  bool _isDaySelectable(DateTime day) {
    final config = _config;
    if (config == null) return true;
    final calendar = DateTime(day.year, day.month, day.day);
    if (config.isClosedDate(calendar)) return false;
    return config.isActiveWeekday(calendar.weekday);
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;
    final config = _config ?? ClinicScheduleConfig.defaultClinic();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      selectableDayPredicate: (day) {
        final calendar = DateTime(day.year, day.month, day.day);
        if (config.isClosedDate(calendar)) return false;
        return config.isActiveWeekday(calendar.weekday);
      },
    );
    if (picked == null || !mounted) return;
    if (!_isDaySelectable(picked)) {
      final calendar = DateTime(picked.year, picked.month, picked.day);
      final message = config.isClosedDate(calendar)
          ? 'Bu tarih kapalı gün olarak işaretli.'
          : 'Bu gün için çalışma saati tanımlı değil.';
      setState(() => _dateNotSelectableMessage = message);
      return;
    }
    setState(() => _dateNotSelectableMessage = null);
    widget.onDateChanged(DateTime(picked.year, picked.month, picked.day));
    widget.onSlotSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _pickDate : null,
            borderRadius: AppRadius.smallBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      compactDateLabel(widget.selectedDate),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_dateNotSelectableMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ClinicalNotice(
              tone: ClinicalNoticeTone.warning,
              dense: true,
              message: _dateNotSelectableMessage!,
            ),
          ),
        FutureBuilder<AppointmentAvailabilityResult>(
          future: _slotsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return ClinicalNotice(
                tone: ClinicalNoticeTone.danger,
                dense: true,
                message: 'Saatler yüklenemedi. Lütfen tekrar deneyin.',
              );
            }

            final result = snapshot.data;
            if (result == null) {
              return const SizedBox.shrink();
            }

            if (result.slots.isEmpty) {
              final tone = result.message != null
                  ? _toneForReason(result.reason)
                  : ClinicalNoticeTone.neutral;
              return ClinicalNotice(
                tone: tone,
                dense: true,
                message:
                    result.message ?? 'Bu gün için müsait saat bulunmuyor.',
              );
            }

            final inlineNotice = result.message != null &&
                    !result.hasSelectableSlot
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ClinicalNotice(
                      tone: _toneForReason(result.reason),
                      dense: true,
                      message: result.message!,
                    ),
                  )
                : null;

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = AppointmentScheduleSection.gridColumnCount(
                  constraints.maxWidth,
                );
                final grid = GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    mainAxisExtent: 36,
                  ),
                  itemCount: result.slots.length,
                  itemBuilder: (context, index) {
                    final slot = result.slots[index];
                    return _AppointmentSlotCell(
                      slot: slot,
                      enabled: widget.enabled,
                      onTap: () {
                        if (!slot.isAvailable &&
                            !slot.isCurrentAppointmentSlot) {
                          return;
                        }
                        widget.onSlotSelected(slot.start);
                      },
                    );
                  },
                );

                if (inlineNotice == null) return grid;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [inlineNotice, grid],
                );
              },
            );
          },
        ),
      ],
    );
  }

  ClinicalNoticeTone _toneForReason(AppointmentDayAvailabilityReason r) {
    switch (r) {
      case AppointmentDayAvailabilityReason.closedDate:
      case AppointmentDayAvailabilityReason.workingDayClosed:
        return ClinicalNoticeTone.warning;
      case AppointmentDayAvailabilityReason.noAvailableSlots:
      case AppointmentDayAvailabilityReason.none:
        return ClinicalNoticeTone.neutral;
    }
  }
}

class _AppointmentSlotCell extends StatelessWidget {
  final AppointmentSlot slot;
  final bool enabled;
  final VoidCallback onTap;

  const _AppointmentSlotCell({
    required this.slot,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectable = slot.isAvailable || slot.isCurrentAppointmentSlot;
    final selected = slot.isSelected;
    final busy = !slot.isAvailable && !slot.isCurrentAppointmentSlot;

    Color background = Colors.transparent;
    Color borderColor = AppColors.borderSoft;
    Color textColor = AppColors.textPrimary;

    if (busy) {
      textColor = AppColors.textSecondary;
    } else if (selected) {
      background = AppColors.primaryDeepTeal.withValues(alpha: 0.14);
      borderColor = AppColors.primaryDeepTeal;
      textColor = AppColors.primaryDeepTeal;
    } else if (slot.isCurrentAppointmentSlot) {
      background = AppColors.accentTurquoise.withValues(alpha: 0.1);
      borderColor = AppColors.accentTurquoise;
      textColor = AppColors.accentTurquoise;
    }

    final cell = Material(
      color: background,
      borderRadius: AppRadius.smallBorder,
      child: InkWell(
        onTap: enabled && selectable ? onTap : null,
        borderRadius: AppRadius.smallBorder,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.smallBorder,
            border: Border.all(
              color: borderColor,
              width: slot.isCurrentAppointmentSlot ? 1.5 : 1,
            ),
          ),
          child: Text(
            slot.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
              decoration: busy ? TextDecoration.lineThrough : null,
              decorationColor: textColor.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );

    if (!slot.isCurrentAppointmentSlot) return cell;

    return Semantics(
      label: 'Mevcut randevu ${slot.label}',
      button: selectable,
      child: cell,
    );
  }
}
