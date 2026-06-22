import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/audit/models/audit_log.dart';
import '../../features/pdf_outputs/models/pdf_output.dart';
import '../../features/patients/models/patient_timeline_event.dart';

/// Küçük durum/etiket chip'i — semantic AppColors token'ları.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipTone tone;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusChipTone.neutral,
    this.icon,
  });

  factory StatusChip.pdfStatus(PdfStatus status) {
    return StatusChip(
      label: pdfStatusLabel(status),
      tone: _pdfTone(status),
      icon: Icons.description_outlined,
    );
  }

  factory StatusChip.timelineEvent(TimelineEventType type) {
    return StatusChip(
      label: timelineEventTypeLabel(type),
      tone: _timelineTone(type),
      icon: iconForTimeline(type),
    );
  }

  static IconData iconForTimeline(TimelineEventType type) => _timelineIcon(type);

  factory StatusChip.auditAction(ActionType type) {
    return StatusChip(
      label: actionTypeLabel(type),
      tone: _auditTone(type),
      icon: iconForAudit(type),
    );
  }

  static IconData iconForAudit(ActionType type) => _auditIcon(type);

  factory StatusChip.module(ModuleType module) {
    return StatusChip(
      label: moduleTypeLabel(module),
      tone: StatusChipTone.info,
      icon: Icons.layers_outlined,
    );
  }

  static StatusChipTone _pdfTone(PdfStatus status) {
    switch (status) {
      case PdfStatus.taslak:
        return StatusChipTone.neutral;
      case PdfStatus.hazirlandi:
        return StatusChipTone.info;
      case PdfStatus.hastayaVerildi:
      case PdfStatus.gonderildi:
        return StatusChipTone.success;
      case PdfStatus.iptal:
        return StatusChipTone.danger;
    }
  }

  static StatusChipTone _timelineTone(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.muayeneNotu:
      case TimelineEventType.tani:
      case TimelineEventType.tedaviPlani:
        return StatusChipTone.info;
      case TimelineEventType.ameliyatGirisim:
      case TimelineEventType.postOpProtokol:
        return StatusChipTone.warning;
      case TimelineEventType.odeme:
      case TimelineEventType.pdfCikti:
        return StatusChipTone.success;
      case TimelineEventType.auditLog:
        return StatusChipTone.neutral;
      default:
        return StatusChipTone.neutral;
    }
  }

  static IconData _timelineIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.randevu:
        return Icons.event_outlined;
      case TimelineEventType.muayeneNotu:
        return Icons.medical_services_outlined;
      case TimelineEventType.goruntuleme:
        return Icons.image_search_outlined;
      case TimelineEventType.ameliyatGirisim:
        return Icons.healing_outlined;
      case TimelineEventType.postOpProtokol:
        return Icons.assignment_outlined;
      case TimelineEventType.fizyoterapiYonlendirme:
      case TimelineEventType.fizyoterapiSeansi:
        return Icons.accessibility_new_outlined;
      case TimelineEventType.egzersizProgrami:
        return Icons.fitness_center_outlined;
      case TimelineEventType.pdfCikti:
        return Icons.picture_as_pdf_outlined;
      case TimelineEventType.odeme:
        return Icons.payments_outlined;
      case TimelineEventType.mesaj:
        return Icons.chat_outlined;
      case TimelineEventType.kvkkOnam:
        return Icons.verified_user_outlined;
      case TimelineEventType.auditLog:
        return Icons.history_outlined;
      default:
        return Icons.timeline_outlined;
    }
  }

  static StatusChipTone _auditTone(ActionType type) {
    switch (type) {
      case ActionType.yetkiDegisikligi:
      case ActionType.dosyaSilme:
        return StatusChipTone.danger;
      case ActionType.pdfOlusturma:
      case ActionType.kayitOlusturma:
        return StatusChipTone.success;
      case ActionType.giris:
        return StatusChipTone.info;
      default:
        return StatusChipTone.neutral;
    }
  }

  static IconData _auditIcon(ActionType type) {
    switch (type) {
      case ActionType.giris:
        return Icons.login_outlined;
      case ActionType.dosyaYukleme:
      case ActionType.dosyaSilme:
        return Icons.folder_outlined;
      case ActionType.pdfOlusturma:
        return Icons.picture_as_pdf_outlined;
      case ActionType.yetkiDegisikligi:
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.touch_app_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForTone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.smallBorder,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _ChipColors _colorsForTone(StatusChipTone tone) {
    switch (tone) {
      case StatusChipTone.success:
        return _ChipColors(
          background: AppColors.successSurface,
          border: AppColors.success.withValues(alpha: 0.25),
          foreground: AppColors.success,
        );
      case StatusChipTone.warning:
        return _ChipColors(
          background: AppColors.warningSurface,
          border: AppColors.warning.withValues(alpha: 0.25),
          foreground: AppColors.warning,
        );
      case StatusChipTone.danger:
        return _ChipColors(
          background: AppColors.dangerSurface,
          border: AppColors.danger.withValues(alpha: 0.25),
          foreground: AppColors.danger,
        );
      case StatusChipTone.info:
        return _ChipColors(
          background: AppColors.infoSurface,
          border: AppColors.info.withValues(alpha: 0.22),
          foreground: AppColors.info,
        );
      case StatusChipTone.neutral:
        return _ChipColors(
          background: AppColors.backgroundSoft,
          border: AppColors.borderSoft,
          foreground: AppColors.textSecondary,
        );
    }
  }
}

enum StatusChipTone { neutral, info, success, warning, danger }

class _ChipColors {
  final Color background;
  final Color border;
  final Color foreground;

  const _ChipColors({
    required this.background,
    required this.border,
    required this.foreground,
  });
}
