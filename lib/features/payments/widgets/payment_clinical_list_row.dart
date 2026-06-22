import 'package:flutter/material.dart';

import '../models/payment_record.dart';
import 'payment_ui_helpers.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/data_list_card.dart';

class PaymentClinicalListRow extends StatelessWidget {
  final PaymentRecord record;
  final VoidCallback onTap;

  const PaymentClinicalListRow({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = paymentStatusLabel(record.paymentStatus);
    final tone = ClinicalListStatusTones.paymentStatus(record.paymentStatus);
    final marker = ClinicalListStatusTones.markerColorForTone(tone);
    final showChip = ClinicalListStatusTones.shouldShowPaymentStatusChip(
        record.paymentStatus);

    final method = record.paymentMethodLabel;
    final subtitleParts = <String>[record.serviceTypeLabel];
    if (method != 'Belirtilmedi') {
      subtitleParts.add(method);
    }

    final dateStr = _formatDate(record.transactionDate);
    final contextLine =
        'Ödenen: ${formatPaymentAmount(record.paidAmount)} · Kalan: ${formatPaymentAmount(record.remainingAmount)}';

    final fileNumber = record.patientFileNumber?.trim();
    final title = fileNumber != null && fileNumber.isNotEmpty
        ? '${record.patientName} — $fileNumber'
        : record.patientName;

    return DataListCard(
      title: title,
      subtitle: subtitleParts.join(' • '),
      metaLine: dateStr,
      contextLine: contextLine,
      accentRailColor: marker,
      semanticChipLabel: showChip ? statusLabel : null,
      semanticChipTone: tone,
      trailing: formatPaymentAmount(record.totalAmount),
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
