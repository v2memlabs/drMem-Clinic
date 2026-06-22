import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';
import 'package:v2mem_clinic/features/patient_files/presentation/patient_file_metadata_list_content.dart';
import 'package:v2mem_clinic/features/patient_files/widgets/patient_file_clinical_list_row.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_load_result.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';

PatientFileMetadata _sampleFile(
    {PatientFileStatus status = PatientFileStatus.active}) {
  return PatientFileMetadata(
    id: 'f-1',
    tenantId: 'tenant-hidden',
    patientId: 'p-1',
    fileKind: PatientFileKind.patientUpload,
    clinicalContext: PatientFileClinicalContext.encounter,
    encounterId: 'enc-uuid',
    displayName: 'Görüntüleme CD',
    originalFileName: 'hidden.dcm',
    mimeType: 'application/dicom',
    fileSizeBytes: 512,
    storageBucket: 'private-bucket',
    storagePath: 't/p/f/hidden.dcm',
    status: status,
    visibilityScope: PatientFileVisibilityScope.clinicOperations,
    metadata: const {'internal_doctor_note': 'secret'},
    createdAt: DateTime(2026, 5, 1, 14, 30),
  );
}

void main() {
  testWidgets('patient file list content uses clinical panel not DataListCard',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientFileMetadataListContent(
            isLoading: false,
            result: PatientFileMetadataListLoadResult.success([_sampleFile()]),
          ),
        ),
      ),
    );

    expect(find.byType(PatientFileClinicalListRow), findsOneWidget);
    expect(find.byType(ClinicalSeparatedListBody), findsOneWidget);
    expect(find.text('Görüntüleme CD'), findsOneWidget);
    expect(find.textContaining('tenant-hidden'), findsNothing);
    expect(find.textContaining('private-bucket'), findsNothing);
    expect(find.textContaining('hidden.dcm'), findsNothing);
    expect(find.textContaining('storage_path'), findsNothing);
    expect(find.textContaining('signed_url'), findsNothing);
    expect(find.textContaining('internal_doctor_note'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('archived file shows semantic chip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientFileClinicalListRow(
            file: _sampleFile(status: PatientFileStatus.archived),
            showPreviewHintOnTap: false,
          ),
        ),
      ),
    );

    expect(find.text('Arşiv'), findsOneWidget);
    expect(find.text('Belge'), findsOneWidget);
  });

  testWidgets('active file hides semantic status chip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientFileClinicalListRow(
            file: _sampleFile(),
            showPreviewHintOnTap: false,
          ),
        ),
      ),
    );

    expect(find.text('Aktif'), findsNothing);
    expect(find.text('Belge'), findsOneWidget);
  });
}
