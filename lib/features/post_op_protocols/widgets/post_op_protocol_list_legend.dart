import '../../../shared/widgets/clinical_status_legend.dart';
import '../../../shared/widgets/status_chip.dart';

/// Post-op takip listesi durum renkleri.
abstract final class PostOpProtocolListLegend {
  static const List<ClinicalStatusLegendItem> items = [
    ClinicalStatusLegendItem(
      label: 'Taslak',
      tone: StatusChipTone.neutral,
    ),
    ClinicalStatusLegendItem(
      label: 'Aktif',
      tone: StatusChipTone.info,
    ),
    ClinicalStatusLegendItem(
      label: 'Güncellenecek',
      tone: StatusChipTone.warning,
    ),
    ClinicalStatusLegendItem(
      label: 'Tamamlandı / Hastaya verildi',
      tone: StatusChipTone.success,
    ),
  ];
}
