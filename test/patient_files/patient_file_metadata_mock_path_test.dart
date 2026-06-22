import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_data_source.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_user_messages.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_files/presentation/patient_file_metadata_list_content.dart';
import 'package:v2mem_clinic/features/patient_files/widgets/patient_file_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    PatientFileMetadataRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('Patient file metadata mock path UI', () {
    testWidgets('mock backend shows clinical rows for patient with files',
        (tester) async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      PatientFileMetadataRepositoryProvider.resetCache();

      final result = await PatientFileMetadataListDataSource.load(
        patientId: 'p1',
      );

      await tester.pumpWidget(
        wrap(
          PatientFileMetadataListContent(
            isLoading: false,
            result: result,
          ),
        ),
      );

      expect(find.byType(PatientFileClinicalListRow), findsWidgets);
      expect(find.byType(ClinicalSeparatedListBody), findsOneWidget);
      expect(find.text('consent_form.pdf'), findsOneWidget);
      expect(find.textContaining('storage_path'), findsNothing);
      expect(find.textContaining('signed_url'), findsNothing);
      expect(find.textContaining('public_url'), findsNothing);
    });

    testWidgets('mock backend empty patient shows safe empty state',
        (tester) async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();

      final result = await PatientFileMetadataListDataSource.load(
        patientId: 'p-empty-unknown',
      );

      await tester.pumpWidget(
        wrap(
          PatientFileMetadataListContent(
            isLoading: false,
            result: result,
          ),
        ),
      );

      expect(find.byType(PatientFileClinicalListRow), findsNothing);
      expect(
        find.text(PatientFileMetadataListUserMessages.emptyForPatient),
        findsOneWidget,
      );
      expect(
        find.text(PatientFileMetadataListUserMessages.notConfigured),
        findsNothing,
      );
    });
  });
}
