import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/async_clinical_encounter_repository_contract.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/assistant_clinical_summary.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_diagnosis_summary_list_screen.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeAssistantClinicalSummaryRepository
    implements AssistantClinicalSummaryRepository {
  _FakeAssistantClinicalSummaryRepository(this._byPatient);

  final Map<String, List<AssistantClinicalSummary>> _byPatient;
  bool listCalled = false;
  String? lastPatientFilter;

  @override
  Future<List<AssistantClinicalSummary>> listAssistantClinicalSummaries({
    String? patientId,
  }) async {
    listCalled = true;
    lastPatientFilter = patientId;
    if (patientId != null && patientId.trim().isNotEmpty) {
      return List<AssistantClinicalSummary>.from(
        _byPatient[patientId.trim()] ?? const [],
      );
    }
    return _byPatient.values.expand((e) => e).toList();
  }

  @override
  Future<AssistantClinicalSummary?> getAssistantClinicalSummary(
    String encounterId,
  ) async {
    for (final list in _byPatient.values) {
      for (final item in list) {
        if (item.encounterId == encounterId) return item;
      }
    }
    return null;
  }
}

AssistantClinicalSummary _safeSummary({
  required String encounterId,
  required String patientId,
  String diagnosis = 'Remote güvenli tanı özeti',
}) {
  return AssistantClinicalSummary(
    encounterId: encounterId,
    tenantId: 'tenant-test',
    patientId: patientId,
    patientDisplayName: 'Remote Hasta',
    encounterDate: DateTime(2026, 5, 10),
    visitType: 'kontrol',
    status: 'tamamlandi',
    diagnosisSummary: diagnosis,
    hasPhysiotherapyReferral: false,
  );
}

class _SpyClinicalEncounterRepo implements AsyncClinicalEncounterRepositoryContract {
  bool getByPatientCalled = false;

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async {
    getByPatientCalled = true;
    return const [];
  }

  @override
  Future<List<ClinicalEncounter>> getAll() async => [];

  @override
  Future<ClinicalEncounter?> getById(String id) async => null;

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async => null;

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

  testWidgets('list uses fake safe summary repo with patient filter', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _FakeAssistantClinicalSummaryRepository({
      'p1': [_safeSummary(encounterId: 'as-1', patientId: 'p1')],
      'p-other': [_safeSummary(encounterId: 'as-2', patientId: 'p-other')],
    });
    ClinicalRoleSummaryRepositoryProvider.resetCache();
    ClinicalRoleSummaryRepositoryProvider.assistantTestOverride = repo;

    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const ClinicalDiagnosisSummaryListScreen(patientId: 'p1'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repo.listCalled, isTrue);
    expect(repo.lastPatientFilter, 'p1');
    expect(find.text('Remote Hasta'), findsOneWidget);
    expect(find.textContaining('Remote güvenli tanı özeti'), findsWidgets);
    expect(find.textContaining('p-other'), findsNothing);
  });

  testWidgets('patient detail assistant section does not call full clinical repo',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final assistantRepo = _FakeAssistantClinicalSummaryRepository({
      'p1': [
        _safeSummary(
          encounterId: 'as-detail',
          patientId: 'p1',
          diagnosis: 'Detay güvenli özet',
        ),
      ],
    });
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    ClinicalRoleSummaryRepositoryProvider.resetCache();
    ClinicalRoleSummaryRepositoryProvider.assistantTestOverride = assistantRepo;

    final clinicalSpy = _SpyClinicalEncounterRepo();
    ClinicalEncounterRepositoryProvider.testOverride = clinicalSpy;

    final router = GoRouter(
      initialLocation: '/patients/p1',
      routes: [
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) =>
              PatientDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(assistantRepo.listCalled, isTrue);
    expect(assistantRepo.lastPatientFilter, 'p1');
    expect(clinicalSpy.getByPatientCalled, isFalse);
    expect(find.text('Klinik Özet'), findsOneWidget);
    expect(find.textContaining('Detay güvenli özet'), findsWidgets);
    expect(find.textContaining('as-detail'), findsNothing);
    expect(find.textContaining('tenant-test'), findsNothing);
  });
}
