import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/async_clinical_encounter_repository_contract.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_form_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

const _encounterId = 'ce-form-bridge';
const _patientId = 'p1';

ClinicalEncounter _encounter({bool flag = false}) {
  return ClinicalEncounter(
    id: _encounterId,
    patientId: _patientId,
    patientName: 'Test Hasta',
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
    doctorName: 'Dr. Test',
    status: ClinicalEncounterStatus.tamamlandi,
    visitType: ClinicalVisitType.kontrol,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: 'Ağrı',
    complaintDuration: '1 ay',
    traumaHistory: false,
    painLocation: '',
    painCharacter: '',
    vasScore: 3,
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
    finalDiagnosis: 'Tanı',
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.diger,
    icdCode: '',
    planTitle: '',
    conservativeTreatment: '',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: flag,
    exerciseRecommendation: 'Egzersiz önerisi',
    imagingRequest: '',
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: 'Özel not',
    orthosisNotes: '',
    treatmentApproach: ClinicalTreatmentApproach.conservative,
  );
}

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeReferralRepo({this.throwOnAdd = false});

  final bool throwOnAdd;

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async {
    if (throwOnAdd) {
      throw StateError('add failed');
    }
    return referral.copyWith(id: 'ref-new-1');
  }

  @override
  Future<PhysiotherapyReferral?> getById(String id) async => null;

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => [];

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      [];

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
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      _encounterReferral();
}

PhysiotherapyReferral _encounterReferral() {
  return PhysiotherapyReferral(
    id: 'ref-1',
    patientId: _patientId,
    patientName: 'Test Hasta',
    referredAt: DateTime(2026, 6, 1),
    referredBy: 'Dr. Test',
    physiotherapistName: 'Fizyoterapist',
    diagnosisSummary: 'Tanı',
    treatmentGoal: 'Hedef',
    precautions: '',
    allowedActivities: '',
    restrictedActivities: '',
    clinicalEncounterId: _encounterId,
  );
}

class _FakeClinicalEncounterRepo implements AsyncClinicalEncounterRepositoryContract {
  _FakeClinicalEncounterRepo(this._byId, {this.throwOnUpdate = false});

  final Map<String, ClinicalEncounter> _byId;
  final bool throwOnUpdate;

  int updateCallCount = 0;

  @override
  Future<ClinicalEncounter?> getById(String id) async => _byId[id];

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async {
    updateCallCount++;
    if (throwOnUpdate) throw StateError('update failed');
    _byId[encounter.id] = encounter;
    return encounter;
  }

  @override
  Future<List<ClinicalEncounter>> getAll() async => [];

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async => [];

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async =>
      null;

  @override
  Future<List<ClinicalEncounter>> search(String query) async => [];

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async =>
      encounter;

  @override
  Future<void> archiveEncounter(String id) async {}
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
    ClinicalEncounterRepositoryProvider.testOverride = null;
    ClinicalEncounterRepositoryProvider.resetCache();
  });

  setUp(() {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      ),
    );
  });

  test('referral add with clinicalEncounterId triggers bridge update', () async {
    final clinicalRepo = _FakeClinicalEncounterRepo({
      _encounterId: _encounter(),
    });
    ClinicalEncounterRepositoryProvider.testOverride = clinicalRepo;
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    final result = await PhysiotherapyReferralFormDataSource.add(
      _encounterReferral(),
    );

    expect(result.hasError, isFalse);
    expect(clinicalRepo.updateCallCount, 1);
    final updated = await clinicalRepo.getById(_encounterId);
    expect(updated?.physiotherapyReferral, isTrue);
  });

  test('referral add without clinicalEncounterId skips bridge', () async {
    final clinicalRepo = _FakeClinicalEncounterRepo({
      _encounterId: _encounter(),
    });
    ClinicalEncounterRepositoryProvider.testOverride = clinicalRepo;
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    final referral = PhysiotherapyReferral(
      id: '',
      patientId: _patientId,
      patientName: 'Test Hasta',
      referredAt: DateTime(2026, 6, 1),
      referredBy: 'Dr. Test',
      physiotherapistName: 'Fizyoterapist',
      diagnosisSummary: 'Tanı',
      treatmentGoal: 'Hedef',
      precautions: '',
      allowedActivities: '',
      restrictedActivities: '',
    );
    final result = await PhysiotherapyReferralFormDataSource.add(referral);

    expect(result.hasError, isFalse);
    expect(clinicalRepo.updateCallCount, 0);
  });

  test('bridge update failure still returns referral success', () async {
    final clinicalRepo = _FakeClinicalEncounterRepo(
      {_encounterId: _encounter()},
      throwOnUpdate: true,
    );
    ClinicalEncounterRepositoryProvider.testOverride = clinicalRepo;
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    final result = await PhysiotherapyReferralFormDataSource.add(
      _encounterReferral(),
    );

    expect(result.hasError, isFalse);
    expect(result.referral?.id, 'ref-new-1');
    expect(clinicalRepo.updateCallCount, 1);
  });
}
