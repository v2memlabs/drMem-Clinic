import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/async_clinical_encounter_repository_contract.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_refresh.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/patient_scoped_clinical_encounter_row.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_user_messages.dart';
import 'package:v2mem_clinic/features/patient_files/presentation/patient_file_metadata_list_content.dart';
import 'package:v2mem_clinic/features/patient_files/widgets/patient_file_clinical_list_row.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

ClinicalEncounter _remoteEncounter({
  required String id,
  required String patientId,
  String finalDx = 'Remote tanı satırı',
}) {
  return ClinicalEncounter(
    id: id,
    patientId: patientId,
    patientName: 'Remote Hasta',
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
    doctorName: 'Dr. Remote',
    status: ClinicalEncounterStatus.tamamlandi,
    visitType: ClinicalVisitType.kontrol,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: 'Ağrı',
    complaintDuration: '1 ay',
    traumaHistory: false,
    painLocation: '',
    painCharacter: '',
    vasScore: 2,
    nightPain: false,
    activityRelation: '',
    previousTreatments: '',
    medications: '',
    allergies: '',
    comorbidities: '',
    previousSurgeries: '',
    generalNotes: '',
    sportsSectionEnabled: false,
    sportBranch: '',
    amateurOrProfessional: '',
    trainingFrequency: '',
    patientExpectation: '',
    returnToSportGoal: '',
    sportsRelated: false,
    returnToSportPlan: '',
    inspection: '',
    palpation: '',
    rangeOfMotion: '',
    muscleStrength: '',
    stabilityTests: '',
    specialTests: '',
    neurovascularStatus: '',
    comparisonWithOtherSide: '',
    clinicalImpression: '',
    imagingSummary: '',
    imagingDoctorComment: '',
    attachedFileNote: '',
    preliminaryDiagnosis: '',
    finalDiagnosis: finalDx,
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: 'M23.2',
    icdTitle: 'İç diz bozukluğu',
    planTitle: 'Plan',
    conservativeTreatment: 'Konservatif',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: false,
    exerciseRecommendation: '',
    imagingRequest: '',
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: 'Gizli not',
    orthosisNotes: '',
    treatmentApproach: ClinicalTreatmentApproach.conservative,
  );
}

class _FakeClinicalEncounterRepo
    implements AsyncClinicalEncounterRepositoryContract {
  _FakeClinicalEncounterRepo(this._byPatient);

  final Map<String, List<ClinicalEncounter>> _byPatient;
  bool getByPatientCalled = false;

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async {
    getByPatientCalled = true;
    return List.unmodifiable(_byPatient[patientId] ?? const []);
  }

  @override
  Future<List<ClinicalEncounter>> getAll() async => [];

  @override
  Future<ClinicalEncounter?> getById(String id) async => null;

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async {
    final list = await getByPatientId(patientId);
    if (list.isEmpty) return null;
    return list.first;
  }

  @override
  Future<List<ClinicalEncounter>> search(String query) async => [];

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async => encounter;

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async =>
      encounter;

  @override
  Future<void> archiveEncounter(String id) async {}
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ClinicalRoleSummaryRepositoryProvider.clearTestOverrides();
    ClinicalRoleSummaryRepositoryProvider.resetCache();
    ClinicalEncounterRepositoryProvider.testOverride = null;
    ClinicalEncounterRepositoryProvider.resetCache();
  });

  Future<GoRouter> pumpPatientDetail(
    WidgetTester tester, {
    required String patientId,
    required String role,
  }) async {
    AuthSession.setUser(
      AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1800, 1400));

    final router = GoRouter(
      initialLocation: '/patients/$patientId',
      routes: [
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) =>
              PatientDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/clinical-records/:id',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Encounter detail')),
            body: const Text('Encounter detail'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    return router;
  }

  group('Patient detail clinical remote reflection', () {
    testWidgets('uses async repository filtered by patientId', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeClinicalEncounterRepo({
        'p1': [
          _remoteEncounter(id: 'ce-remote-1', patientId: 'p1'),
        ],
        'p-other': [
          _remoteEncounter(id: 'ce-other', patientId: 'p-other'),
        ],
      });
      ClinicalEncounterRepositoryProvider.testOverride = repo;

      await pumpPatientDetail(
        tester,
        patientId: 'p1',
        role: AppRoles.doctor,
      );

      expect(repo.getByPatientCalled, isTrue);
      expect(find.byType(PatientScopedClinicalEncounterRow), findsOneWidget);
      expect(find.textContaining('Remote tanı satırı'), findsWidgets);
      expect(find.textContaining('Kontrol'), findsWidgets);
      expect(find.textContaining('internalDoctorNote'), findsNothing);
      expect(find.textContaining('tenant_id'), findsNothing);
      expect(find.textContaining('ce-remote-1'), findsNothing);
    });

    testWidgets('empty list shows safe empty state', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      ClinicalEncounterRepositoryProvider.testOverride =
          _FakeClinicalEncounterRepo({'p1': const []});

      await pumpPatientDetail(
        tester,
        patientId: 'p1',
        role: AppRoles.doctor,
      );

      expect(find.byType(PatientScopedClinicalEncounterRow), findsNothing);
      expect(
        find.text('Bu hasta için henüz muayene kaydı bulunmuyor.'),
        findsOneWidget,
      );
    });

    testWidgets('repository error shows safe message without exception text',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      ClinicalEncounterRepositoryProvider.testOverride =
          _ThrowingClinicalRepo();

      await pumpPatientDetail(
        tester,
        patientId: 'p1',
        role: AppRoles.doctor,
      );

      expect(find.byType(ClinicalStateMessage), findsWidgets);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('StackTrace'), findsNothing);
    });

    testWidgets('stale refresh reloads after markStale on return',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeClinicalEncounterRepo({
        'p1': [
          _remoteEncounter(id: 'ce-a', patientId: 'p1', finalDx: 'İlk tanı'),
        ],
      });
      ClinicalEncounterRepositoryProvider.testOverride = repo;

      final router = await pumpPatientDetail(
        tester,
        patientId: 'p1',
        role: AppRoles.doctor,
      );
      expect(find.textContaining('İlk tanı'), findsWidgets);

      final row = find.byType(PatientScopedClinicalEncounterRow).first;
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      repo._byPatient['p1'] = [
        _remoteEncounter(id: 'ce-b', patientId: 'p1', finalDx: 'Güncel tanı'),
      ];
      ClinicalEncounterListRefresh.markStale();

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Güncel tanı'), findsWidgets);
      expect(find.textContaining('İlk tanı'), findsNothing);
    });

    testWidgets('assistant does not see scoped clinical rows', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      ClinicalEncounterRepositoryProvider.testOverride =
          _FakeClinicalEncounterRepo(
        {
          'p1': [_remoteEncounter(id: 'ce-a', patientId: 'p1')]
        },
      );

      await pumpPatientDetail(
        tester,
        patientId: 'p1',
        role: AppRoles.assistant,
      );

      expect(find.byType(PatientScopedClinicalEncounterRow), findsNothing);
      expect(find.text('Muayene Kayıtları'), findsNothing);
    });

    testWidgets('nurse does not see scoped clinical rows', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpPatientDetail(
        tester,
        patientId: 'p1',
        role: AppRoles.nurse,
      );

      expect(find.byType(PatientScopedClinicalEncounterRow), findsNothing);
      expect(find.text('Muayene Kayıtları'), findsNothing);
    });

    testWidgets(
        'file metadata section uses provider path without leaking storage fields',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      ClinicalEncounterRepositoryProvider.testOverride =
          _FakeClinicalEncounterRepo({'p1': const []});

      await pumpPatientDetail(tester, patientId: 'p1', role: AppRoles.doctor);

      expect(find.text('Dosya ve PDF Kayıtları'), findsOneWidget);
      expect(find.byType(PatientFileMetadataListContent), findsOneWidget);
      expect(find.textContaining('storage_path'), findsNothing);
      expect(find.textContaining('signed_url'), findsNothing);
      expect(find.textContaining('public_url'), findsNothing);
      expect(find.byType(PatientFileClinicalListRow), findsWidgets);
      expect(
        find.text(PatientFileMetadataListUserMessages.notConfigured),
        findsNothing,
      );
    });
  });
}

class _ThrowingClinicalRepo
    implements AsyncClinicalEncounterRepositoryContract {
  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async {
    throw Exception('PostgREST tenant_id leak simulation');
  }

  @override
  Future<List<ClinicalEncounter>> getAll() async => throw UnimplementedError();

  @override
  Future<ClinicalEncounter?> getById(String id) async =>
      throw UnimplementedError();

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async =>
      throw UnimplementedError();

  @override
  Future<List<ClinicalEncounter>> search(String query) async =>
      throw UnimplementedError();

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async =>
      throw UnimplementedError();

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async =>
      throw UnimplementedError();

  @override
  Future<void> archiveEncounter(String id) async => throw UnimplementedError();
}
