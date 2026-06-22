import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_lookup_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_failure.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';

const _remoteUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

PhysiotherapyReferral _remoteReferral() {
  return PhysiotherapyReferral(
    id: _remoteUuid,
    patientId: 'p-remote',
    patientName: 'Remote Hasta',
    referredAt: DateTime(2026, 5, 15),
    referredBy: 'Dr. Test',
    physiotherapistName: 'Fizyoterapist A',
    diagnosisSummary: 'ACL sonrası rehab',
    treatmentGoal: 'Stabilite kazanımı',
    precautions: 'Pivot yok',
    allowedActivities: 'Bisiklet',
    restrictedActivities: 'Koşu',
    targetReturnToSportDate: DateTime(2026, 12, 1),
    doctorSummary: 'Gizli doktor özeti',
    notes: 'Güvenli not',
  );
}

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeReferralRepo({this.throwOnGet = false});

  final bool throwOnGet;

  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (throwOnGet) {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.network,
      );
    }
    if (id == _remoteUuid) return _remoteReferral();
    return null;
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

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      _remoteReferral();
}

void main() {
  tearDown(() {
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  test('getById returns referral from async repo', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    final result =
        await PhysiotherapyReferralLookupDataSource.getById(_remoteUuid);

    expect(result.isFound, isTrue);
    expect(result.referral?.patientName, 'Remote Hasta');
    expect(result.referral?.diagnosisSummary, 'ACL sonrası rehab');
  });

  test('getById not found returns safe empty result', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    final result =
        await PhysiotherapyReferralLookupDataSource.getById('missing-id');

    expect(result.isFound, isFalse);
    expect(result.referral, isNull);
  });

  test('repository exception does not leak technical error text', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo(throwOnGet: true);

    final result =
        await PhysiotherapyReferralLookupDataSource.getById(_remoteUuid);

    expect(result.isFound, isFalse);
    expect(result.referral, isNull);
  });

  test('generic exception does not leak to result', () async {
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _ThrowingReferralRepo();

    final result =
        await PhysiotherapyReferralLookupDataSource.getById(_remoteUuid);

    expect(result.isFound, isFalse);
  });
}

class _ThrowingReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    throw Exception('PostgREST JWT tenant_id violation stack trace');
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => throw UnimplementedError();

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      throw UnimplementedError();

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async =>
      throw UnimplementedError();

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      throw UnimplementedError();

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      throw UnimplementedError();
}
