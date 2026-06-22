import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/data/async_appointment_repository_contract.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/async_clinical_encounter_repository_contract.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';
import 'package:v2mem_clinic/features/dashboard/data/dashboard_workbench_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_failure.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/consents/data/async_consent_repository_contract.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_provider.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/async_pdf_output_repository_contract.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository_failure.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository_provider.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

ClinicalEncounter _encounterToday() {
  return ClinicalEncounter(
    id: 'ce-dash-1',
    patientId: 'p1',
    patientName: 'Hasta',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    doctorName: 'Dr',
    status: ClinicalEncounterStatus.tamamlandi,
    visitType: ClinicalVisitType.ilkMuayene,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: 'Ağrı',
    complaintDuration: '1 hafta',
    traumaHistory: false,
    painLocation: '',
    painCharacter: '',
    vasScore: 1,
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
    preliminaryDiagnosis: 'Ön tanı',
    finalDiagnosis: 'Tanı',
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: 'M23',
    icdTitle: 'ICD',
    planTitle: 'Plan',
    conservativeTreatment: '',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: false,
    exerciseRecommendation: '',
    imagingRequest: '',
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: 'Gizli',
    orthosisNotes: '',
    treatmentApproach: ClinicalTreatmentApproach.conservative,
  );
}

PdfOutput _pdfToday() {
  return PdfOutput(
    id: 'pdf-dash-1',
    patientId: 'p1',
    patientName: 'Hasta',
    createdAt: DateTime.now(),
    documentType: DocumentType.muayeneOzeti,
    title: 'Dashboard PDF',
    contentSummary: 'Gizli özet',
    warningNote: '',
    createdBy: 'Dr',
    status: PdfStatus.hazirlandi,
    storagePath: 'tenant/p1/secret.pdf',
    storageBucket: 'patient-files-private',
  );
}

class _TrackingClinicalRepo implements AsyncClinicalEncounterRepositoryContract {
  _TrackingClinicalRepo(this._list);

  final List<ClinicalEncounter> _list;
  bool getAllCalled = false;

  @override
  Future<List<ClinicalEncounter>> getAll() async {
    getAllCalled = true;
    return _list;
  }

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async => [];

  @override
  Future<ClinicalEncounter?> getById(String id) async => null;

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async =>
      null;

  @override
  Future<List<ClinicalEncounter>> search(String query) async => [];

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async =>
      encounter;

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async =>
      encounter;

  @override
  Future<void> archiveEncounter(String id) async {}
}

class _FakeConsentRepoForDashboard implements AsyncConsentRepositoryContract {
  _FakeConsentRepoForDashboard({required this.pendingCount});

  final int pendingCount;
  bool countPendingCalled = false;

  @override
  Future<int> countPending() async {
    countPendingCalled = true;
    return pendingCount;
  }

  @override
  Future<List<ConsentRecord>> getAll() async => const [];

  @override
  Future<List<ConsentRecord>> getByPatientId(String patientId) async =>
      const [];

  @override
  Future<ConsentRecord?> getById(String id) async => null;

  @override
  Future<List<ConsentRecord>> search(String query) async => const [];

  @override
  Future<ConsentRecord> add(ConsentRecord consent) async => consent;

  @override
  Future<ConsentRecord> update(ConsentRecord consent) async => consent;
}

PhysiotherapyReferral _referral({
  required String id,
  ReferralStatus status = ReferralStatus.yeni,
}) {
  return PhysiotherapyReferral(
    id: id,
    patientId: 'p1',
    patientName: 'Test Hasta',
    referredAt: DateTime(2026, 6, 1),
    referredBy: 'Dr. Test',
    physiotherapistName: 'Fizyoterapist',
    diagnosisSummary: 'Tanı',
    treatmentGoal: 'Hedef',
    precautions: '',
    allowedActivities: '',
    restrictedActivities: '',
    status: status,
  );
}

class _FakeReferralRepoForDashboard
    implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeReferralRepoForDashboard(
    this._items, {
    this.throwOnGetFiltered = false,
  });

  final List<PhysiotherapyReferral> _items;
  final bool throwOnGetFiltered;
  bool getFilteredCalled = false;
  ReferralStatus? lastStatusFilter;

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async {
    getFilteredCalled = true;
    lastStatusFilter = statusEnumFilter;
    if (throwOnGetFiltered) {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.notConfigured,
      );
    }
    if (statusEnumFilter == null) {
      return List.unmodifiable(_items);
    }
    return _items.where((r) => r.status == statusEnumFilter).toList();
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => List.unmodifiable(_items);

  @override
  Future<PhysiotherapyReferral?> getById(String id) async => null;

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async => [];

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

class _FakePdfRepo implements AsyncPdfOutputRepositoryContract {
  _FakePdfRepo(this._outputs, {this.throwOnGetAll = false});

  final List<PdfOutput> _outputs;
  final bool throwOnGetAll;
  bool getAllCalled = false;

  @override
  Future<List<PdfOutput>> getAll() async {
    getAllCalled = true;
    if (throwOnGetAll) {
      throw const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.notConfigured,
      );
    }
    return List.unmodifiable(_outputs);
  }

  @override
  Future<PdfOutput?> getById(String id) async => null;

  @override
  Future<List<PdfOutput>> getByPatientId(String patientId) async => [];

  @override
  Future<List<PdfOutput>> search(String query) async => [];
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ClinicalEncounterRepositoryProvider.testOverride = null;
    ClinicalEncounterRepositoryProvider.resetCache();
    ConsentRepositoryProvider.clearTestOverrides();
    ConsentRepositoryProvider.resetCache();
    PdfOutputRepositoryProvider.testOverride = null;
    PdfOutputRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  test('doctor snapshot includes today appointments and pending planlandi', () async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.doctor,
    );

    expect(snap.appointmentsUnavailable, isFalse);
    expect(snap.todayAppointmentCount, isNotNull);
    expect(snap.todayAppointmentCount, greaterThanOrEqualTo(0));
    expect(snap.pendingAppointmentCount, isNotNull);
    expect(
      snap.todayAppointments
          .where((a) => a.status == AppointmentStatus.planlandi)
          .length,
      snap.pendingAppointmentCount,
    );
    expect(snap.todayClinicalEncounterCount, isNotNull);
  });

  test('doctor PDF count uses pdfOutputsAsync registry path', () async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final pdfRepo = _FakePdfRepo([_pdfToday()]);
    PdfOutputRepositoryProvider.testOverride = pdfRepo;

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.doctor,
    );

    expect(pdfRepo.getAllCalled, isTrue);
    expect(snap.pdfOutputsUnavailable, isFalse);
    expect(snap.todayPdfOutputCount, 1);
  });

  test('doctor PDF repo soft failure shows unavailable not crash', () async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    PdfOutputRepositoryProvider.testOverride =
        _FakePdfRepo(const [], throwOnGetAll: true);

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.doctor,
    );

    expect(snap.pdfOutputsUnavailable, isTrue);
    expect(snap.todayPdfOutputCount, isNull);
  });

  test('doctor clinical count uses clinicalEncountersAsync', () async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final clinicalRepo = _TrackingClinicalRepo([_encounterToday()]);
    ClinicalEncounterRepositoryProvider.testOverride = clinicalRepo;

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.doctor,
    );

    expect(clinicalRepo.getAllCalled, isTrue);
    expect(snap.clinicalEncountersUnavailable, isFalse);
    expect(snap.todayClinicalEncounterCount, 1);
  });

  test('assistant snapshot has no clinical encounter count', () async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );

    final clinicalRepo = _TrackingClinicalRepo([_encounterToday()]);
    ClinicalEncounterRepositoryProvider.testOverride = clinicalRepo;

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.assistant,
    );

    expect(snap.todayClinicalEncounterCount, isNull);
    expect(snap.clinicalEncountersUnavailable, isFalse);
    expect(clinicalRepo.getAllCalled, isFalse);
    expect(snap.todayAppointmentCount, isNotNull);
    expect(snap.todayPdfOutputCount, isNull);
  });

  test('nurse snapshot includes inventory counts when permitted', () async {
    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Nurse',
        role: AppRoles.nurse,
      ),
    );

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.nurse,
    );

    expect(snap.lowStockCount, isNotNull);
    expect(snap.expiringSoonCount, isNotNull);
    expect(snap.expiredStockCount, isNotNull);
    expect(snap.inventoryUnavailable, isFalse);
  });

  test('assistant pending consent count uses consentsAsync', () async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );

    final consentRepo = _FakeConsentRepoForDashboard(pendingCount: 3);
    ConsentRepositoryProvider.testOverride = consentRepo;

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.assistant,
    );

    expect(consentRepo.countPendingCalled, isTrue);
    expect(snap.pendingConsentCount, 3);
  });

  test('physiotherapist snapshot counts only yeni referrals', () async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'physio',
        displayName: 'Physio',
        role: AppRoles.physiotherapist,
      ),
    );

    final referralRepo = _FakeReferralRepoForDashboard([
      _referral(id: 'r-new-1'),
      _referral(id: 'r-new-2'),
      _referral(id: 'r-devam', status: ReferralStatus.devam),
      _referral(
        id: 'r-doktor',
        status: ReferralStatus.doktor_degerlendirmesi_bekliyor,
      ),
    ]);
    PhysiotherapyReferralRepositoryProvider.testOverride = referralRepo;

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.physiotherapist,
    );

    expect(referralRepo.getFilteredCalled, isTrue);
    expect(referralRepo.lastStatusFilter, ReferralStatus.yeni);
    expect(snap.physiotherapyReferralsUnavailable, isFalse);
    expect(snap.newPhysiotherapyReferralCount, 2);
  });

  test('physiotherapist referral soft failure shows unavailable', () async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'physio',
        displayName: 'Physio',
        role: AppRoles.physiotherapist,
      ),
    );

    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepoForDashboard(const [], throwOnGetFiltered: true);

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.physiotherapist,
    );

    expect(snap.physiotherapyReferralsUnavailable, isTrue);
    expect(snap.newPhysiotherapyReferralCount, isNull);
  });

  test('doctor snapshot has no physiotherapy referral count', () async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final referralRepo = _FakeReferralRepoForDashboard([_referral(id: 'r1')]);
    PhysiotherapyReferralRepositoryProvider.testOverride = referralRepo;

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.doctor,
    );

    expect(referralRepo.getFilteredCalled, isFalse);
    expect(snap.newPhysiotherapyReferralCount, isNull);
    expect(snap.physiotherapyReferralsUnavailable, isFalse);
  });

  test('assistant snapshot has no physiotherapy referral count', () async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );

    final referralRepo = _FakeReferralRepoForDashboard([_referral(id: 'r1')]);
    PhysiotherapyReferralRepositoryProvider.testOverride = referralRepo;

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.assistant,
    );

    expect(referralRepo.getFilteredCalled, isFalse);
    expect(snap.newPhysiotherapyReferralCount, isNull);
  });

  test('schedule preview caps at seven rows', () async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final snap = await DashboardWorkbenchDataSource.load(
      DashboardWorkbenchProfile.doctor,
    );

    expect(snap.schedulePreview.length, lessThanOrEqualTo(7));
  });
}
