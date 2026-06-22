import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_display.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';

void main() {
  final sample = PatientFileMetadata(
    id: 'f-1',
    tenantId: 'tenant-secret',
    patientId: 'p-1',
    fileKind: PatientFileKind.generatedPdf,
    clinicalContext: PatientFileClinicalContext.encounter,
    encounterId: 'enc-uuid',
    displayName: 'Muayene Özeti',
    originalFileName: 'ozet.pdf',
    mimeType: 'application/pdf',
    fileSizeBytes: 2048,
    storageBucket: 'patient-files-private',
    storagePath: 'tenant/patient/secret.pdf',
    status: PatientFileStatus.active,
    visibilityScope: PatientFileVisibilityScope.doctorAdmin,
    createdAt: DateTime(2026, 5, 20, 14, 30),
    isGeneratedPdf: true,
  );

  group('PatientFileMetadataDisplay', () {
    test('relation label hides technical ids', () {
      expect(
        PatientFileMetadataDisplay.relationContextLabel(sample),
        'Muayene kaydına bağlı',
      );
      expect(
        PatientFileMetadataDisplay.relationContextLabel(sample),
        isNot(contains('enc-uuid')),
      );
    });

    test('formatFileSize is user friendly', () {
      expect(PatientFileMetadataDisplay.formatFileSize(2048), '2.0 KB');
    });

    test('chips include status not storage fields', () {
      final chips = PatientFileMetadataDisplay.chipsFor(sample);
      expect(chips, contains('Aktif'));
      expect(chips, contains('PDF'));
      expect(chips.any((c) => c.contains('patient-files')), isFalse);
    });

    test('list row helpers hide storage and raw mime', () {
      expect(
        PatientFileMetadataDisplay.listNeutralChipLabel(sample),
        'PDF',
      );
      final meta = PatientFileMetadataDisplay.listMetaLinesFor(sample);
      expect(meta.any((l) => l.contains('enc-uuid')), isFalse);
      expect(meta.any((l) => l.contains('secret.pdf')), isFalse);
      expect(meta.any((l) => l.contains('application/')), isFalse);
    });
  });
}
