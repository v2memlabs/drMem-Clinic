import '../../../shared/widgets/clinical_status_legend.dart';
import '../../../shared/widgets/status_chip.dart';

/// Ödeme listesi durum renkleri.
abstract final class PaymentListLegend {
  static const List<ClinicalStatusLegendItem> items = [
    ClinicalStatusLegendItem(
      label: 'Ödendi',
      tone: StatusChipTone.success,
    ),
    ClinicalStatusLegendItem(
      label: 'Kısmi / Bekliyor',
      tone: StatusChipTone.warning,
    ),
    ClinicalStatusLegendItem(
      label: 'İptal / İade',
      tone: StatusChipTone.danger,
    ),
  ];
}
