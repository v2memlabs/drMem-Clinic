import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/audit/models/audit_log.dart';
import 'premium_surface.dart';
import 'status_chip.dart';

/// Audit log liste kartı — okunabilir işlem özeti.
class AuditLogCard extends StatelessWidget {
  final AuditLog log;
  final VoidCallback? onTap;

  const AuditLogCard({
    super.key,
    required this.log,
    this.onTap,
  });

  String get _dateTimeLabel {
    final local = log.createdAt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$d.$m.${local.year} $time';
  }

  String get _patientLine {
    if (log.patientName != null && log.patientName!.trim().isNotEmpty) {
      return log.patientName!.trim();
    }
    if (log.patientId != null && log.patientId!.isNotEmpty) {
      return 'Hasta kaydı bağlı';
    }
    return 'Hasta ilişkisi yok';
  }

  bool get _isSensitive =>
      log.actionType == ActionType.yetkiDegisikligi ||
      log.actionType == ActionType.dosyaSilme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        child: DecoratedBox(
          decoration: PremiumSurface.card(elevated: false),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumSurface.iconBadge(
                  icon: StatusChip.iconForAudit(log.actionType),
                  accent: _isSensitive ? AppColors.danger : AppColors.navy,
                  compact: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              actionTypeLabel(log.actionType),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDeepTeal,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _dateTimeLabel,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        log.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${log.userName} • ${log.userRole} • $_patientLine',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          StatusChip.module(log.module),
                          if (_isSensitive)
                            const StatusChip(
                              label: 'Önemli işlem',
                              tone: StatusChipTone.danger,
                              icon: Icons.priority_high_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
