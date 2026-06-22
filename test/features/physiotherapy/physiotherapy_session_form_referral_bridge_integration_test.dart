import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_session_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_form_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';

const _referralId = 'ref-form-bridge';

PhysiotherapyReferral _referral({ReferralStatus status = ReferralStatus.yeni}) {
  return PhysiotherapyReferral(
    id: _referralId,
    patientId: 'p1',
    patientName: 'Test Hasta',
    referredAt: DateTime(2026, 6, 1),
    referredBy: 'Dr. Test',
    physiotherapistName: 'Fizyoterapist',
    diagnosisSummary: 'Özet',
    treatmentGoal: 'Hedef',
    precautions: '',
    allowedActivities: '',
    restrictedActivities: '',
    status: status,
  );
}

PhysiotherapySessionNote _session({
  bool doctorNotificationNeeded = false,
}) {
  return PhysiotherapySessionNote(
    id: 'pending',
    patientId: 'p1',
    patientName: 'Test Hasta',
    sessionDate: DateTime(2026, 6, 10),
    physiotherapistName: 'Fizyoterapist',
    painScore: 2,
    rangeOfMotionSummary: 'ROM',
    strengthSummary: 'Kuvvet',
    functionalAssessment: 'Fonksiyonel',
    exercisesPerformed: 'Egzersiz',
    homeProgramCompliance: 'İyi',
    warningSigns: '-',
    returnToSportStage: ReturnToSportStage.agri_kontrolu,
    referralId: _referralId,
    doctorNotificationNeeded: doctorNotificationNeeded,
  );
}

class _MutableReferralRepoForFormBridge
    implements AsyncPhysiotherapyReferralRepositoryContract {
  _MutableReferralRepoForFormBridge(PhysiotherapyReferral initial)
      : _byId = {initial.id: initial};

  final Map<String, PhysiotherapyReferral> _byId;
  int updateCallCount = 0;

  ReferralStatus statusFor(String id) => _byId[id]!.status;

  @override
  Future<PhysiotherapyReferral?> getById(String id) async => _byId[id];

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async {
    updateCallCount++;
    final current = _byId[id]!;
    final updated = current.copyWith(status: update.status ?? current.status);
    _byId[id] = updated;
    return updated;
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => _byId.values.toList();

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
  }) async {
    final all = _byId.values.toList();
    if (statusEnumFilter == null) return all;
    return all.where((r) => r.status == statusEnumFilter).toList();
  }

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;
}

class _FakeSessionRepoForFormBridge
    implements AsyncPhysiotherapySessionRepositoryContract {
  @override
  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session) async {
    return PhysiotherapySessionNote(
      id: 'sess-saved-1',
      patientId: session.patientId,
      patientName: session.patientName,
      sessionDate: session.sessionDate,
      physiotherapistName: session.physiotherapistName,
      painScore: session.painScore,
      rangeOfMotionSummary: session.rangeOfMotionSummary,
      strengthSummary: session.strengthSummary,
      functionalAssessment: session.functionalAssessment,
      exercisesPerformed: session.exercisesPerformed,
      homeProgramCompliance: session.homeProgramCompliance,
      warningSigns: session.warningSigns,
      returnToSportStage: session.returnToSportStage,
      doctorNotificationNeeded: session.doctorNotificationNeeded,
      notes: session.notes,
      referralId: session.referralId,
    );
  }

  @override
  Future<List<PhysiotherapySessionNote>> getAll() async => [];

  @override
  Future<List<PhysiotherapySessionNote>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<List<PhysiotherapySessionNote>> getByReferralId(
    String referralId,
  ) async =>
      [];

  @override
  Future<PhysiotherapySessionNote?> getById(String id) async => null;
}

void main() {
  tearDown(() {
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapySessionRepositoryProvider.clearTestOverrides();
    PhysiotherapySessionRepositoryProvider.resetCache();
  });

  test('session save updates yeni referral to devam', () async {
    final referralRepo = _MutableReferralRepoForFormBridge(_referral());
    PhysiotherapyReferralRepositoryProvider.testOverride = referralRepo;
    PhysiotherapySessionRepositoryProvider.testOverride =
        _FakeSessionRepoForFormBridge();

    final result = await PhysiotherapySessionFormDataSource.add(_session());

    expect(result.hasError, isFalse);
    expect(referralRepo.updateCallCount, 1);
    expect(referralRepo.statusFor(_referralId), ReferralStatus.devam);
  });

  test('session save with doctor notification escalates status', () async {
    final referralRepo = _MutableReferralRepoForFormBridge(
      _referral(status: ReferralStatus.devam),
    );
    PhysiotherapyReferralRepositoryProvider.testOverride = referralRepo;
    PhysiotherapySessionRepositoryProvider.testOverride =
        _FakeSessionRepoForFormBridge();

    final result = await PhysiotherapySessionFormDataSource.add(
      _session(doctorNotificationNeeded: true),
    );

    expect(result.hasError, isFalse);
    expect(
      referralRepo.statusFor(_referralId),
      ReferralStatus.doktor_degerlendirmesi_bekliyor,
    );
  });

  test('yeni filter count drops after session save bridge', () async {
    final referralRepo = _MutableReferralRepoForFormBridge(_referral());
    PhysiotherapyReferralRepositoryProvider.testOverride = referralRepo;
    PhysiotherapySessionRepositoryProvider.testOverride =
        _FakeSessionRepoForFormBridge();

    final before = await referralRepo.getFiltered(
      statusEnumFilter: ReferralStatus.yeni,
    );
    expect(before, hasLength(1));

    await PhysiotherapySessionFormDataSource.add(_session());

    final after = await referralRepo.getFiltered(
      statusEnumFilter: ReferralStatus.yeni,
    );
    expect(after, isEmpty);
  });

  test('bridge update failure does not fail session save', () async {
    final referralRepo = _ThrowingUpdateReferralRepo(_referral());
    PhysiotherapyReferralRepositoryProvider.testOverride = referralRepo;
    PhysiotherapySessionRepositoryProvider.testOverride =
        _FakeSessionRepoForFormBridge();

    final result = await PhysiotherapySessionFormDataSource.add(_session());

    expect(result.hasError, isFalse);
    expect(result.session?.id, 'sess-saved-1');
  });
}

class _ThrowingUpdateReferralRepo
    implements AsyncPhysiotherapyReferralRepositoryContract {
  _ThrowingUpdateReferralRepo(this._referral);

  final PhysiotherapyReferral _referral;

  @override
  Future<PhysiotherapyReferral?> getById(String id) async => _referral;

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async {
    throw StateError('update denied');
  }

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
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;
}
