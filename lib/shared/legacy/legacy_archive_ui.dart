import 'package:flutter/material.dart';

/// Legacy arşiv liste ekranlarında kullanılan ortak metin ve küçük bileşenler.
const String kLegacyArchiveNotice =
    'Yeni klinik kayıtlar Muayene Kayıtları üzerinden oluşturulur. '
    'Bu ekran geçmiş/legacy kayıtların görüntülenmesi içindir.';

const String kLegacyArchiveChipLabel = 'Arşiv';

Widget legacyArchiveNoticeText(BuildContext context) {
  final muted = Theme.of(context).colorScheme.onSurfaceVariant;
  return Text(
    kLegacyArchiveNotice,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
  );
}

Widget legacyArchiveChip(BuildContext context) {
  return Chip(
    label: const Text(kLegacyArchiveChipLabel),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

String legacyFormatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

String legacyFormatDateTime(DateTime date) {
  final local = date.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '${legacyFormatDate(local)} $time';
}
