import '../../../shared/widgets/clinical_status_legend.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/surgery_procedure_list_display.dart';
import '../models/surgery_procedure_note.dart';

/// Ameliyat / işlem listesi tip renkleri.
abstract final class SurgeryProcedureListLegend {
  static List<ClinicalStatusLegendItem> get items => [
        ClinicalStatusLegendItem(
          label: 'Ameliyat',
          tone: StatusChipTone.neutral,
          color: SurgeryProcedureListDisplay.markerColorForType(
            ProcedureType.ameliyat,
          ),
        ),
        ClinicalStatusLegendItem(
          label: 'Girişim',
          tone: StatusChipTone.neutral,
          color: SurgeryProcedureListDisplay.markerColorForType(
            ProcedureType.artroskopi,
          ),
        ),
        ClinicalStatusLegendItem(
          label: 'İşlem',
          tone: StatusChipTone.neutral,
          color: SurgeryProcedureListDisplay.markerColorForType(
            ProcedureType.kontrolAmacli,
          ),
        ),
        ClinicalStatusLegendItem(
          label: 'Pansuman',
          tone: StatusChipTone.neutral,
          color: SurgeryProcedureListDisplay.markerColorForType(
            ProcedureType.yaraPansuman,
          ),
        ),
      ];
}
