import 'dart:typed_data';

import '../../clinical_encounter/models/clinical_encounter.dart';
import '../models/pdf_output.dart';
import '../services/pdf_generator_service.dart';

/// PDF bytes üretim sırası — form snapshot + opsiyonel muayene snapshot.
abstract final class PdfOutputBytesBuilder {
  static Future<Uint8List?> buildForSave({
    required PdfOutput draft,
    ClinicalEncounter? encounterSnapshot,
    String? patientFileNumber,
  }) async {
    final generator = PdfGeneratorService.instance;

    if (generator.canGenerateFromPdfOutput(draft) && encounterSnapshot != null) {
      final generated = await generator.generateClinicalEncounterSummary(
        encounter: encounterSnapshot,
        createdBy: draft.createdBy,
        warningNote: draft.warningNote,
        patientFileNumber: patientFileNumber,
      );
      return generated.bytes;
    }

    final generated = await generator.generateFromFormSnapshot(
      output: draft,
      patientFileNumber: patientFileNumber,
    );
    return generated.bytes;
  }
}
