import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/pdf_outputs/models/pdf_output.dart';
import 'premium_surface.dart';
import 'status_chip.dart';

/// PDF çıktı liste kartı — belge odaklı görünüm.
class PdfDocumentCard extends StatelessWidget {
  final PdfOutput output;
  final VoidCallback? onTap;

  const PdfDocumentCard({
    super.key,
    required this.output,
    this.onTap,
  });

  String get _dateLabel {
    final local = output.createdAt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }

  String? get _sourceLabel {
    final module = output.sourceModule?.trim() ?? '';
    if (module.isEmpty) return null;
    return 'Kaynak: ${pdfSourceModuleLabel(module)}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = output.contentSummary.trim();
    final metaParts = <String>[
      output.patientName,
      'Oluşturan: ${output.createdBy}',
      if (summary.isNotEmpty) summary,
    ];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        child: DecoratedBox(
          decoration: PremiumSurface.card(elevated: true),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: PremiumSurface.listAccentRail(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: PremiumSurface.iconBadge(
                    icon: Icons.picture_as_pdf_outlined,
                    accent: AppColors.primaryDeepTeal,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    documentTypeLabel(output.documentType),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDeepTeal,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    output.title.trim().isEmpty
                                        ? output.patientName
                                        : output.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _dateLabel,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          metaParts.join(' • '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xxs,
                          runSpacing: AppSpacing.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip.pdfStatus(output.status),
                            if (_sourceLabel != null)
                              StatusChip(
                                label: _sourceLabel!,
                                tone: StatusChipTone.info,
                                icon: Icons.link_outlined,
                              ),
                          ],
                        ),
                      ],
                    ),
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
