import 'package:flutter/material.dart';

import '../models/consent_record.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/data_list_card.dart';

class ConsentClinicalListRow extends StatelessWidget {
  final ConsentRecord record;
  final VoidCallback onTap;

  const ConsentClinicalListRow({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = consentStatusLabel(record.status);
    final tone = ClinicalListStatusTones.consentStatus(record.status);
    final marker = ClinicalListStatusTones.markerColorForTone(tone);
    final showChip =
        ClinicalListStatusTones.shouldShowConsentStatusChip(record.status);

    final file = record.documentFileName?.trim() ?? '';

    return DataListCard(
      title: record.patientName,
      subtitle: consentTypeLabel(record.consentType),
      metaLine: file.isNotEmpty ? file : null,
      accentRailColor: marker,
      semanticChipLabel: showChip ? statusLabel : null,
      semanticChipTone: tone,
      trailing: _formatDate(record.createdAt),
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
