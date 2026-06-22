import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_session_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/patient_rehab_referral_summary_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';

const _patientId = 'p-rehab-summary';
const _referralId = 'ref-latest';

PhysiotherapyReferral _referral() {
  return PhysiotherapyReferral(
    id: _referralId,
    patientId: _patientId,
    patientName: 'Test',
    referredAt: DateTime(2026, 6, 1),
    referredBy: 'Dr',
    physiotherapistName: 'Fizyo',
    diagnosisSummary: 'Tanı',
    treatmentGoal: 'Hedef',
    precautions: '',
    allowedActivities: '',
    restrictedActivities: '',
  );
}

PhysiotherapySessionNote _session({
  required String id,
  required DateTime sessionDate,
}) {
  return PhysiotherapySessionNote(
    id: id,
    patientId: _patientId,
    patientName: 'Test',
    sessionDate: sessionDate,
    physiotherapistName: 'Fizyo',
    painScore: 4,
    rangeOfMotionSummary: '',
    strengthSummary: '',
    functionalAssessment: '',
    exercisesPerformed: '',
    homeProgramCompliance: 'İyi',
    warningSigns: '',
    returnToSportStage: ReturnToSportStage.agri_kontrolu,
    referralId: _referralId,
  );
}

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeReferralRepo(this._items, {this.throwOnGet = false});

  final List<PhysiotherapyReferral> _items;
  final bool throwOnGet;

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async {
    if (throwOnGet) throw StateError('referral failed');
    return _items.where((r) => r.patientId == patientId).toList();
  }

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
  _FakeSessionRepo(this._byReferral, {this.throwOnGetByReferral = false});

  final Map<String, List<PhysiotherapySessionNote>> _byReferral;
  final bool throwOnGetByReferral;

  String? lastReferralId;

  @override
  Future<List<PhysiotherapySessionNote>> getByReferralId(
    String referralId,
  ) async {
    lastReferralId = referralId;
    if (throwOnGetByReferral) throw StateError('session failed');
    return List.unmodifiable(_byReferral[referralId] ?? const []);
  }

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
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapySessionRepositoryProvider.clearTestOverrides();
    PhysiotherapySessionRepositoryProvider.resetCache();
  });

  test('loadSummary returns latest session for latest referral', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo([_referral()]);
    final sessionRepo = _FakeSessionRepo({
      _referralId: [
        _session(id: 's-old', sessionDate: DateTime(2026, 5, 1)),
        _session(id: 's-new', sessionDate: DateTime(2026, 6, 20)),
      ],
    });
    PhysiotherapySessionRepositoryProvider.testOverride = sessionRepo;

    final result = await PatientRehabReferralSummaryDataSource.loadSummary(
      _patientId,
    );

    expect(result.hasError, isFalse);
    expect(sessionRepo.lastReferralId, _referralId);
    expect(result.latestSession?.id, 's-new');
  });

  test('loadSummary with no sessions keeps referral and null session', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo([_referral()]);
    PhysiotherapySessionRepositoryProvider.testOverride =
        _FakeSessionRepo({_referralId: []});

    final result = await PatientRehabReferralSummaryDataSource.loadSummary(
      _patientId,
    );

    expect(result.hasError, isFalse);
    expect(result.referrals, hasLength(1));
    expect(result.latestSession, isNull);
  });

  test('session load failure degrades to referral-only', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo([_referral()]);
    PhysiotherapySessionRepositoryProvider.testOverride = _FakeSessionRepo(
      {_referralId: [_session(id: 's1', sessionDate: DateTime(2026, 6, 1))]},
      throwOnGetByReferral: true,
    );

    final result = await PatientRehabReferralSummaryDataSource.loadSummary(
      _patientId,
    );

    expect(result.hasError, isFalse);
    expect(result.referrals, hasLength(1));
    expect(result.latestSession, isNull);
  });

  test('referral load failure surfaces error', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo(
      [_referral()],
      throwOnGet: true,
    );
    PhysiotherapySessionRepositoryProvider.testOverride = _FakeSessionRepo({});

    final result = await PatientRehabReferralSummaryDataSource.loadSummary(
      _patientId,
    );

    expect(result.hasError, isTrue);
    expect(result.referrals, isNull);
  });
}
