import 'package:flutter/material.dart';

import '../../../shared/widgets/data_list_card.dart';
import '../models/lab_order.dart';

class LabOrderListRow extends StatelessWidget {
  final LabOrder order;
  final VoidCallback onTap;

  const LabOrderListRow({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final testSummary = order.selectedTests.isEmpty
        ? 'Tahlil seçilmedi'
        : '${order.selectedTests.length} tahlil';
    final meta = <String>[
      order.diagnosis.trim().isEmpty
          ? 'Tanı belirtilmedi'
          : order.diagnosis.trim(),
      labOrderStatusLabel(order.status),
      if (order.templateName != null) order.templateName!,
    ];
    final protocol = order.displayProtocolNumber;
    if (protocol != null) {
      meta.insert(0, 'Protokol: $protocol');
    }

    return DataListCard(
      title: order.patientName,
      subtitle: testSummary,
      metaLine: meta.isNotEmpty ? meta.first : null,
      contextLine: meta.length > 1 ? meta.sublist(1).join(' • ') : null,
      trailing: _formatDate(order.createdAt),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
