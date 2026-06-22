import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_load_result.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_user_messages.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata.dart';
import 'package:v2mem_clinic/features/patient_files/models/patient_file_metadata_enums.dart';
import 'package:v2mem_clinic/features/patient_files/presentation/patient_file_metadata_list_content.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';

PatientFileMetadata _sampleFile() {
  return PatientFileMetadata(
    id: 'f-1',
    tenantId: 'tenant-hidden',
    patientId: 'p-1',
    fileKind: PatientFileKind.patientUpload,
    clinicalContext: PatientFileClinicalContext.patient,
    displayName: 'Görüntüleme CD',
    originalFileName: 'cd.dcm',
    mimeType: 'application/dicom',
    fileSizeBytes: 512,
    storageBucket: 'private-bucket',
    storagePath: 't/p/f/hidden.dcm',
    status: PatientFileStatus.active,
    visibilityScope: PatientFileVisibilityScope.clinicOperations,
    metadata: const {'internal_doctor_note': 'secret'},
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('PatientFileMetadataListContent', () {
    testWidgets('renders safe metadata fields only', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientFileMetadataListContent(
            isLoading: false,
            result: PatientFileMetadataListLoadResult.success([_sampleFile()]),
          ),
        ),
      );

      expect(find.byType(ClinicalSeparatedListBody), findsOneWidget);
      expect(find.text('Görüntüleme CD'), findsOneWidget);
      expect(find.textContaining('tenant-hidden'), findsNothing);
      expect(find.textContaining('private-bucket'), findsNothing);
      expect(find.textContaining('hidden.dcm'), findsNothing);
      expect(find.textContaining('internal_doctor_note'), findsNothing);
      expect(find.textContaining('secret'), findsNothing);
    });

    testWidgets('empty state copy', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientFileMetadataListContent(
            isLoading: false,
            result: PatientFileMetadataListLoadResult.success(const []),
          ),
        ),
      );

      expect(
        find.text(PatientFileMetadataListUserMessages.emptyForPatient),
        findsOneWidget,
      );
    });

    testWidgets('notConfigured state without crash', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientFileMetadataListContent(
            isLoading: false,
            result: PatientFileMetadataListLoadResult.notConfigured(),
          ),
        ),
      );

      expect(
        find.text(PatientFileMetadataListUserMessages.notConfigured),
        findsOneWidget,
      );
    });

    testWidgets('error state hides technical failure', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientFileMetadataListContent(
            isLoading: false,
            result: PatientFileMetadataListLoadResult.failure(
              'hidden internal',
            ),
            onRetry: () {},
          ),
        ),
      );

      expect(
        find.text(PatientFileMetadataListUserMessages.errorTitle),
        findsOneWidget,
      );
      expect(find.textContaining('hidden internal'), findsNothing);
      expect(find.textContaining('Postgrest'), findsNothing);
    });

    testWidgets('tap does not expose storage path in UI', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientFileMetadataListContent(
            isLoading: false,
            result: PatientFileMetadataListLoadResult.success([_sampleFile()]),
          ),
        ),
      );

      await tester.tap(find.text('Görüntüleme CD'));
      await tester.pump();
      expect(find.textContaining('hidden.dcm'), findsNothing);
      expect(find.textContaining('t/p/f'), findsNothing);
    });
  });
}
