import 'package:flutter/material.dart';

import '../../../shared/widgets/data_list_card.dart';
import '../models/clinical_report.dart';

class ClinicalReportListRow extends StatelessWidget {
  final ClinicalReport report;
  final VoidCallback onTap;

  const ClinicalReportListRow({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      report.diagnosis.trim().isEmpty
          ? 'Tanı belirtilmedi'
          : report.diagnosis.trim(),
      clinicalReportStatusLabel(report.status),
    ];
    final protocol = report.displayProtocolNumber;
    if (protocol != null) {
      meta.insert(0, 'Protokol: $protocol');
    }
    final reportNo = report.displayReportNumber;
    if (reportNo != null) {
      meta.insert(0, 'Rapor: $reportNo');
    }

    return DataListCard(
      title: report.patientName,
      subtitle: clinicalReportTypeLabel(report.reportType),
      metaLine: meta.isNotEmpty ? meta.first : null,
      contextLine: meta.length > 1 ? meta.sublist(1).join(' • ') : null,
      trailing: _formatDate(report.createdAt),
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
