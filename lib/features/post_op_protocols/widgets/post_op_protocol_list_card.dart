import 'package:flutter/material.dart';

import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/data_list_card.dart';
import '../models/post_op_protocol.dart';

/// Post-op hibrit liste kartı — [DataListCard] + Tip 3 durum tonları.
class PostOpProtocolListCard extends StatelessWidget {
  final PostOpProtocol protocol;
  final VoidCallback onTap;

  const PostOpProtocolListCard({
    super.key,
    required this.protocol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = postOpProtocolStatusLabel(protocol.status);
    final tone = ClinicalListStatusTones.postOpProtocolStatus(protocol.status);
    final marker = ClinicalListStatusTones.markerColorForTone(tone);
    final showChip = ClinicalListStatusTones.shouldShowPostOpProtocolStatusChip(
      protocol.status,
    );

    final summary = protocol.diagnosisOrProcedureSummary.trim();
    final physio = protocol.physiotherapyInstructions.trim();

    return DataListCard(
      title: protocol.patientName,
      subtitle: protocol.protocolTitle,
      metaLine: summary.isEmpty ? null : summary,
      contextLine: physio.isEmpty ? null : 'Fizyoterapi: $physio',
      trailing: _formatDate(protocol.createdAt),
      chips: [postOpPhaseLabel(protocol.phase)],
      accentRailColor: marker,
      semanticChipLabel: showChip ? statusLabel : null,
      semanticChipTone: tone,
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
