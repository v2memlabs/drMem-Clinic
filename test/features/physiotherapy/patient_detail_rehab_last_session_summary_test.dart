import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/async_clinical_encounter_repository_contract.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_session_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

const _patientId = 'p1';
const _referralId = 'ref-patient-detail';

PhysiotherapyReferral _referral() {
  return PhysiotherapyReferral(
    id: _referralId,
    patientId: _patientId,
    patientName: 'Ahmet Yılmaz',
    referredAt: DateTime(2026, 6, 1),
    referredBy: 'Dr',
    physiotherapistName: 'Fizyoterapist',
    diagnosisSummary: 'Diz rehabilitasyonu',
    treatmentGoal: 'Ağrısız yürüme',
    precautions: '',
    allowedActivities: '',
    restrictedActivities: '',
  );
}

PhysiotherapySessionNote _session({
  bool doctorNotificationNeeded = true,
}) {
  return PhysiotherapySessionNote(
    id: 'sess-detail-1',
    patientId: _patientId,
    patientName: 'Ahmet Yılmaz',
    sessionDate: DateTime(2026, 6, 12),
    physiotherapistName: 'Fizyoterapist',
    painScore: 5,
    rangeOfMotionSummary: 'ROM gizli',
    strengthSummary: 'Kuvvet gizli',
    functionalAssessment: 'Fonksiyonel gizli',
    exercisesPerformed: 'Egzersiz gizli',
    homeProgramCompliance: 'Orta',
    warningSigns: '',
    returnToSportStage: ReturnToSportStage.hareket_acikligi,
    doctorNotificationNeeded: doctorNotificationNeeded,
    notes: 'Tam seans notu gizli kalmalı',
    referralId: _referralId,
  );
}

class _EmptyClinicalRepo implements AsyncClinicalEncounterRepositoryContract {
  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<ClinicalEncounter?> getById(String id) async => null;

  @override
  Future<List<ClinicalEncounter>> getAll() async => [];

  @override
  Future<List<ClinicalEncounter>> search(String query) async => [];

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async =>
      null;

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async =>
      encounter;

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async =>
      encounter;

  @override
  Future<void> archiveEncounter(String id) async {}
}

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeReferralRepo(this._items);

  final List<PhysiotherapyReferral> _items;

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      _items.where((r) => r.patientId == patientId).toList();

  @override
  Future<PhysiotherapyReferral?> getById(String id) async => null;

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => _items;

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async => [];

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async =>
      [];

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      _items.first;
}

class _FakeSessionRepo implements AsyncPhysiotherapySessionRepositoryContract {
  _FakeSessionRepo(this._byReferral);

  final Map<String, List<PhysiotherapySessionNote>> _byReferral;

  @override
  Future<List<PhysiotherapySessionNote>> getByReferralId(
    String referralId,
  ) async =>
      List.unmodifiable(_byReferral[referralId] ?? const []);

  @override
  Future<List<PhysiotherapySessionNote>> getAll() async => [];

  @override
  Future<List<PhysiotherapySessionNote>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<PhysiotherapySessionNote?> getById(String id) async => null;

  @override
  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session) async =>
      session;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ClinicalEncounterRepositoryProvider.testOverride = null;
    ClinicalEncounterRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapySessionRepositoryProvider.clearTestOverrides();
    PhysiotherapySessionRepositoryProvider.resetCache();
  });

  Future<void> pumpPatientDetail(
    WidgetTester tester, {
    required String role,
    required List<PhysiotherapyReferral> referrals,
    Map<String, List<PhysiotherapySessionNote>> sessionsByReferral = const {},
  }) async {
    AuthSession.setUser(
      AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      ),
    );

    ClinicalEncounterRepositoryProvider.testOverride = _EmptyClinicalRepo();
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo(referrals);
    PhysiotherapySessionRepositoryProvider.testOverride =
        _FakeSessionRepo(sessionsByReferral);

    final router = GoRouter(
      initialLocation: '/patients/$_patientId',
      routes: [
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) =>
              PatientDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor sees last session date and VAS in rehab card', (
    tester,
  ) async {
    await pumpPatientDetail(
      tester,
      role: AppRoles.doctor,
      referrals: [_referral()],
      sessionsByReferral: {_referralId: [_session()]},
    );

    expect(find.text('Rehabilitasyon Özeti'), findsOneWidget);
    expect(find.text('Son FTR seansı'), findsOneWidget);
    expect(find.textContaining('12.06.2026'), findsOneWidget);
    expect(find.textContaining('VAS: 5/10'), findsOneWidget);
    expect(find.textContaining('Hareket Açıklığı'), findsOneWidget);
    expect(find.textContaining('Doktor değerlendirmesi gerekli'), findsOneWidget);
    expect(find.textContaining('Tam seans notu gizli'), findsNothing);
    expect(find.textContaining('ROM gizli'), findsNothing);
    expect(find.textContaining('sess-detail-1'), findsNothing);
    expect(find.textContaining(_referralId), findsNothing);
  });

  testWidgets('referral without session keeps referral summary only', (
    tester,
  ) async {
    await pumpPatientDetail(
      tester,
      role: AppRoles.doctor,
      referrals: [_referral()],
      sessionsByReferral: {_referralId: []},
    );

    expect(find.text('Rehabilitasyon Özeti'), findsOneWidget);
    expect(find.textContaining('Diz rehabilitasyonu'), findsOneWidget);
    expect(find.text('Son FTR seansı'), findsNothing);
  });

  testWidgets('assistant and nurse do not see rehab summary card', (
    tester,
  ) async {
    for (final role in [AppRoles.assistant, AppRoles.nurse]) {
      await pumpPatientDetail(
        tester,
        role: role,
        referrals: [_referral()],
        sessionsByReferral: {_referralId: [_session()]},
      );

      expect(find.text('Rehabilitasyon Özeti'), findsNothing);
      expect(find.text('Son FTR seansı'), findsNothing);
    }
  });

  testWidgets('doctorNotificationNeeded false hides doctor alert row', (
    tester,
  ) async {
    await pumpPatientDetail(
      tester,
      role: AppRoles.doctor,
      referrals: [_referral()],
      sessionsByReferral: {
        _referralId: [_session(doctorNotificationNeeded: false)],
      },
    );

    expect(find.textContaining('VAS: 5/10'), findsOneWidget);
    expect(find.textContaining('Doktor değerlendirmesi gerekli'), findsNothing);
  });
}
