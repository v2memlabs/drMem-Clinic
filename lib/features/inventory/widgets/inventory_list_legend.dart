import '../../../shared/widgets/clinical_status_legend.dart';
import '../../../shared/widgets/status_chip.dart';

/// Stok listesi uyarı renkleri.
abstract final class InventoryListLegend {
  static const List<ClinicalStatusLegendItem> items = [
    ClinicalStatusLegendItem(
      label: 'SKT geçmiş',
      tone: StatusChipTone.danger,
    ),
    ClinicalStatusLegendItem(
      label: 'SKT yakın / Düşük stok',
      tone: StatusChipTone.warning,
    ),
  ];
}
