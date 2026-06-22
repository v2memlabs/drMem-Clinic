import '../../../shared/widgets/clinical_status_legend.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/clinical_encounter.dart';

/// Muayene listesi durum renkleri açıklaması.
abstract final class ClinicalEncounterListLegend {
  static List<ClinicalStatusLegendItem> get items => [
        ClinicalStatusLegendItem(
          label: ClinicalEncounterStatus.taslak.label,
          tone: StatusChipTone.neutral,
        ),
        ClinicalStatusLegendItem(
          label: ClinicalEncounterStatus.tamamlandi.label,
          tone: StatusChipTone.success,
        ),
        ClinicalStatusLegendItem(
          label: ClinicalEncounterStatus.kontrolPlanlandi.label,
          tone: StatusChipTone.warning,
        ),
        ClinicalStatusLegendItem(
          label: ClinicalEncounterStatus.fizyoterapiyeYonlendirildi.label,
          tone: StatusChipTone.info,
        ),
        ClinicalStatusLegendItem(
          label: ClinicalEncounterStatus.ameliyatPlanlandi.label,
          tone: StatusChipTone.warning,
        ),
      ];
}
