import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generator service does not use sync ClinicalEncounterRepository', () {
    final source = File(
      'lib/features/pdf_outputs/services/pdf_generator_service.dart',
    ).readAsStringSync();
    expect(source.contains('ClinicalEncounterRepository'), isFalse);
    expect(source.contains('PatientRepository'), isFalse);
    expect(source.contains('generateFromFormSnapshot'), isTrue);
    expect(source.contains('required ClinicalEncounter encounter'), isTrue);
  });

  test('form snapshot template does not import repositories', () {
    final source = File(
      'lib/features/pdf_outputs/services/templates/form_snapshot_pdf_template.dart',
    ).readAsStringSync();
    expect(source.contains('Repository'), isFalse);
    expect(source.contains('getById'), isFalse);
  });

  test('pdf form uses async source loader for encounter and appointment', () {
    final source = File(
      'lib/features/pdf_outputs/pdf_output_form_screen.dart',
    ).readAsStringSync();
    expect(source.contains('ClinicalEncounterRepository.instance'), isFalse);
    expect(source.contains('PdfFormSourceLoader.loadClinicalEncounter'), isTrue);
    expect(source.contains('PdfFormSourceLoader.loadAppointment'), isTrue);
    expect(source.contains('PdfFormSourceLoader.loadSurgeryNote'), isTrue);
    expect(source.contains('PdfFormSourceLoader.loadImagingNote'), isTrue);
    expect(source.contains('PdfFormSourceLoader.loadPostOpProtocol'), isTrue);
    expect(source.contains('PdfFormSourceLoader.loadExercisePlan'), isTrue);
    expect(source.contains('PdfOutputBytesBuilder.buildForSave'), isTrue);
  });

  test('pdf module prefill has no sync repository getters', () {
    final source = File(
      'lib/features/pdf_outputs/pdf_module_prefill.dart',
    ).readAsStringSync();
    expect(source.contains('Repository.instance'), isFalse);
  });
}
