import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../appointments/models/appointment.dart';
import '../../../shared/widgets/premium_surface.dart';

/// Bugünkü randevu akışı — saat sıralı, en fazla 7 satır.
class DashboardTodayScheduleList extends StatelessWidget {
  final List<Appointment> appointments;
  final bool appointmentsUnavailable;

  const DashboardTodayScheduleList({
    super.key,
    required this.appointments,
    this.appointmentsUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: PremiumSurface.panel(),
          child: appointmentsUnavailable
              ? _UnavailableBody()
              : appointments.isEmpty
                  ? const _EmptyBody()
                  : Column(
                      children: [
                        for (var i = 0; i < appointments.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                          _ScheduleRow(appointment: appointments[i]),
                        ],
                      ],
                    ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/appointments'),
            child: const Text('Tüm randevular'),
          ),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Bugün için randevu görünmüyor.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _UnavailableBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Randevu özeti şu an yüklenemedi.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final Appointment appointment;

  const _ScheduleRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dt = appointment.appointmentDateTime;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              appointment.patientName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(label: appointmentStatusLabel(appointment.status)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
