import '../../../shared/widgets/clinical_status_legend.dart';
import '../../../shared/widgets/status_chip.dart';

/// Randevu listesi durum renkleri açıklaması.
abstract final class AppointmentListLegend {
  static const List<ClinicalStatusLegendItem> items = [
    ClinicalStatusLegendItem(
      label: 'Planlandı',
      tone: StatusChipTone.warning,
    ),
    ClinicalStatusLegendItem(
      label: 'Geldi',
      tone: StatusChipTone.success,
    ),
    ClinicalStatusLegendItem(
      label: 'Gelmedi',
      tone: StatusChipTone.danger,
    ),
    ClinicalStatusLegendItem(
      label: 'Ertelendi',
      tone: StatusChipTone.warning,
    ),
    ClinicalStatusLegendItem(
      label: 'İptal',
      tone: StatusChipTone.danger,
    ),
  ];
}
