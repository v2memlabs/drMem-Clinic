import '../../../shared/widgets/clinical_status_legend.dart';
import '../../../shared/widgets/status_chip.dart';

/// Onam listesi durum renkleri.
abstract final class ConsentListLegend {
  static const List<ClinicalStatusLegendItem> items = [
    ClinicalStatusLegendItem(
      label: 'Alındı',
      tone: StatusChipTone.success,
    ),
    ClinicalStatusLegendItem(
      label: 'Bekliyor / Süresi doldu',
      tone: StatusChipTone.warning,
    ),
    ClinicalStatusLegendItem(
      label: 'Red / İptal',
      tone: StatusChipTone.danger,
    ),
  ];
}
