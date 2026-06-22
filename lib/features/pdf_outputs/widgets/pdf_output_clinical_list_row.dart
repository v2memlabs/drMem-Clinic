import 'package:flutter/material.dart';

import '../models/pdf_output.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/data_list_card.dart';

class PdfOutputClinicalListRow extends StatelessWidget {
  final PdfOutput output;
  final VoidCallback onTap;

  const PdfOutputClinicalListRow({
    super.key,
    required this.output,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = output.title.trim().isNotEmpty
        ? output.title.trim()
        : documentTypeLabel(output.documentType);
    final statusLabel = pdfStatusLabel(output.status);
    final tone = ClinicalListStatusTones.pdfStatus(output.status);
    final showChip =
        ClinicalListStatusTones.shouldShowPdfStatusChip(output.status);
    final marker = showChip
        ? ClinicalListStatusTones.markerColorForTone(tone)
        : null;

    return DataListCard(
      title: title,
      subtitle: output.patientName,
      metaLine: _formatDate(output.createdAt),
      contextLine: 'Oluşturan: ${output.createdBy}',
      chips: const ['PDF'],
      accentRailColor: marker,
      semanticChipLabel: showChip ? statusLabel : null,
      semanticChipTone: tone,
      trailing: _formatDate(output.createdAt),
      onTap: onTap,
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }
}
