import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/detail_header_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/post_op_protocol.dart';

/// Post-op detay üst özeti — hibrit [DetailHeaderCard] + Tip 3 durum.
class PostOpProtocolDetailHeader extends StatelessWidget {
  final PostOpProtocol protocol;
  final String? fileNumber;

  const PostOpProtocolDetailHeader({
    super.key,
    required this.protocol,
    this.fileNumber,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = postOpProtocolStatusLabel(protocol.status);
    final statusTone =
        ClinicalListStatusTones.postOpProtocolStatus(protocol.status);
    final showStatusChip =
        ClinicalListStatusTones.shouldShowPostOpProtocolStatusChip(
      protocol.status,
    );
    final created = _formatDate(protocol.createdAt);

    final subtitleParts = <String>[protocol.patientName];
    if (fileNumber != null && fileNumber!.trim().isNotEmpty) {
      subtitleParts.add('Dosya ${fileNumber!.trim()}');
    }
    subtitleParts.add('Oluşturulma: $created');

    final chips = <Widget>[
      StatusChip(
        label: postOpPhaseLabel(protocol.phase),
        tone: StatusChipTone.neutral,
      ),
      if (showStatusChip)
        StatusChip(
          label: statusLabel,
          tone: statusTone,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DetailHeaderCard(
        title: protocol.protocolTitle,
        subtitle: subtitleParts.join(' · '),
        chips: chips,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }
}

/// @deprecated [PostOpProtocolDetailHeader] kullanın.
typedef PostOpProtocolIdentityBand = PostOpProtocolDetailHeader;
