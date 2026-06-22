import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/async_clinical_encounter_repository_contract.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_ftr_bridge_data_source.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_refresh.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

const _encounterId = 'ce-bridge-test';

ClinicalEncounter _encounter({
  bool physiotherapyReferral = false,
  String internalNote = 'Gizli iç not',
  String exerciseRecommendation = 'Quad set',
}) {
  return ClinicalEncounter(
    id: _encounterId,
    patientId: 'p1',
    patientName: 'Test Hasta',
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
    doctorName: 'Dr. Test',
    status: ClinicalEncounterStatus.tamamlandi,
    visitType: ClinicalVisitType.kontrol,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: 'Ağrı',
    complaintDuration: '2 hafta',
    traumaHistory: false,
    painLocation: 'Diz',
    painCharacter: 'Sürekli',
    vasScore: 4,
    nightPain: false,
    activityRelation: 'Yürüme',
    previousTreatments: '',
    medications: '',
    allergies: '',
    comorbidities: '',
    previousSurgeries: '',
    generalNotes: 'Genel not',
    sportsSectionEnabled: false,
    sportBranch: '',
    amateurOrProfessional: '',
    trainingFrequency: '',
    patientExpectation: '',
    returnToSportGoal: '',
    sportsRelated: false,
    returnToSportPlan: '',
    inspection: 'Normal',
    palpation: 'Hassas',
    rangeOfMotion: '120°',
    muscleStrength: '4/5',
    stabilityTests: 'Stabil',
    specialTests: 'Negatif',
    neurovascularStatus: 'Normal',
    comparisonWithOtherSide: 'Simetrik',
    clinicalImpression: 'Menisküs şüphesi',
    imagingSummary: 'MR normal',
    imagingDoctorComment: 'Yorum',
    attachedFileNote: 'Dosya',
    preliminaryDiagnosis: 'Ön tanı',
    finalDiagnosis: 'Kesin tanı',
    differentialDiagnosis: 'Ayırıcı',
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: 'M23',
    icdTitle: 'Menisküs',
    planTitle: 'Konservatif plan',
    conservativeTreatment: 'İstirahat',
    medicationNotes: 'NSAID',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: physiotherapyReferral,
    exerciseRecommendation: exerciseRecommendation,
    imagingRequest: 'MR',
    surgeryRecommendation: '',
    patientInformationNote: 'Bilgi',
    warningNotes: 'Uyarı',
    internalDoctorNote: internalNote,
    orthosisNotes: 'Ortez',
    treatmentApproach: ClinicalTreatmentApproach.conservative,
  );
}

class _FakeClinicalEncounterRepo implements AsyncClinicalEncounterRepositoryContract {
  _FakeClinicalEncounterRepo(this._byId, {this.throwOnUpdate = false});

  final Map<String, ClinicalEncounter> _byId;
  final bool throwOnUpdate;

  int updateCallCount = 0;
  ClinicalEncounter? lastUpdated;

  @override
  Future<ClinicalEncounter?> getById(String id) async => _byId[id];

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async {
    updateCallCount++;
    if (throwOnUpdate) {
      throw StateError('update failed');
    }
    lastUpdated = encounter;
    _byId[encounter.id] = encounter;
    return encounter;
  }

  @override
  Future<List<ClinicalEncounter>> getAll() async => _byId.values.toList();

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async =>
      _byId.values.where((e) => e.patientId == patientId).toList();

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async {
    final list = await getByPatientId(patientId);
    return list.isEmpty ? null : list.first;
  }

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
    ClinicalEncounterRepositoryProvider.testOverride = null;
    ClinicalEncounterRepositoryProvider.resetCache();
  });

  void setDoctor() {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      ),
    );
  }

  test('empty clinicalEncounterId is no-op', () async {
    setDoctor();
    final repo = _FakeClinicalEncounterRepo({});
    ClinicalEncounterRepositoryProvider.testOverride = repo;

    await ClinicalEncounterFtrBridgeDataSource.syncReferralFlagAfterReferralCreate(
      '  ',
    );

    expect(repo.updateCallCount, 0);
  });

  test('non-doctor role is no-op', () async {
    AuthSession.setUser(
      AppUser(
        id: 'ph1',
        username: 'physio',
        displayName: 'Fizyoterapist',
        role: AppRoles.physiotherapist,
      ),
    );
    final repo = _FakeClinicalEncounterRepo({
      _encounterId: _encounter(),
    });
    ClinicalEncounterRepositoryProvider.testOverride = repo;

    await ClinicalEncounterFtrBridgeDataSource.syncReferralFlagAfterReferralCreate(
      _encounterId,
    );

    expect(repo.updateCallCount, 0);
  });

  test('encounter not found is no-op', () async {
    setDoctor();
    final repo = _FakeClinicalEncounterRepo({});
    ClinicalEncounterRepositoryProvider.testOverride = repo;

    await ClinicalEncounterFtrBridgeDataSource.syncReferralFlagAfterReferralCreate(
      _encounterId,
    );

    expect(repo.updateCallCount, 0);
  });

  test('flag already true skips update', () async {
    setDoctor();
    final repo = _FakeClinicalEncounterRepo({
      _encounterId: _encounter(physiotherapyReferral: true),
    });
    ClinicalEncounterRepositoryProvider.testOverride = repo;

    await ClinicalEncounterFtrBridgeDataSource.syncReferralFlagAfterReferralCreate(
      _encounterId,
    );

    expect(repo.updateCallCount, 0);
  });

  test('sets physiotherapyReferral true and preserves fields', () async {
    setDoctor();
    final original = _encounter(
      internalNote: 'Korunacak özel not',
      exerciseRecommendation: 'Proprioception',
    );
    final repo = _FakeClinicalEncounterRepo({_encounterId: original});
    ClinicalEncounterRepositoryProvider.testOverride = repo;
    final versionBefore = ClinicalEncounterListRefresh.version;

    await ClinicalEncounterFtrBridgeDataSource.syncReferralFlagAfterReferralCreate(
      _encounterId,
    );

    expect(repo.updateCallCount, 1);
    final updated = repo.lastUpdated!;
    expect(updated.physiotherapyReferral, isTrue);
    expect(updated.internalDoctorNote, 'Korunacak özel not');
    expect(updated.exerciseRecommendation, 'Proprioception');
    expect(updated.finalDiagnosis, original.finalDiagnosis);
    expect(updated.conservativeTreatment, original.conservativeTreatment);
    expect(updated.chiefComplaint, original.chiefComplaint);
    expect(
      ClinicalEncounterListRefresh.version,
      greaterThan(versionBefore),
    );
  });

  test('update failure is swallowed', () async {
    setDoctor();
    final repo = _FakeClinicalEncounterRepo(
      {_encounterId: _encounter()},
      throwOnUpdate: true,
    );
    ClinicalEncounterRepositoryProvider.testOverride = repo;

    await expectLater(
      ClinicalEncounterFtrBridgeDataSource.syncReferralFlagAfterReferralCreate(
        _encounterId,
      ),
      completes,
    );
    expect(repo.updateCallCount, 1);
  });
}
