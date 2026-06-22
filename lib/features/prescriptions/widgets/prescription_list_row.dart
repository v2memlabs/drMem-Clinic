import 'package:flutter/material.dart';

import '../../../shared/widgets/data_list_card.dart';
import '../models/prescription.dart';

class PrescriptionListRow extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onTap;

  const PrescriptionListRow({
    super.key,
    required this.prescription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final medCount = prescription.medications.length;

    return DataListCard(
      title: prescription.patientName,
      subtitle: prescription.diagnosis.trim().isEmpty
          ? 'Tanı belirtilmedi'
          : prescription.diagnosis.trim(),
      metaLine: '$medCount ilaç',
      contextLine: prescriptionStatusLabel(prescription.status),
      trailing: _formatDate(prescription.createdAt),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }
}
