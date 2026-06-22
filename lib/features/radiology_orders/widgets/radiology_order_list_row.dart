import 'package:flutter/material.dart';

import '../../../shared/widgets/data_list_card.dart';
import '../models/radiology_order.dart';

class RadiologyOrderListRow extends StatelessWidget {
  final RadiologyOrder order;
  final VoidCallback onTap;

  const RadiologyOrderListRow({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final modalities = order.lines
        .map((l) => radiologyModalityLabel(l.modality))
        .join(', ');
    final meta = <String>[
      order.diagnosis.trim().isEmpty
          ? 'Tanı belirtilmedi'
          : order.diagnosis.trim(),
      radiologyOrderStatusLabel(order.status),
    ];
    final protocol = order.displayProtocolNumber;
    if (protocol != null) {
      meta.insert(0, 'Protokol: $protocol');
    }

    return DataListCard(
      title: order.patientName,
      subtitle: modalities.isEmpty ? 'Modality seçilmedi' : modalities,
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
