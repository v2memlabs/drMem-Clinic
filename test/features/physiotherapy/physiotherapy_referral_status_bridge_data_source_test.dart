import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_status_bridge_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';

const _referralId = 'ref-bridge-1';

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

class _FakeBridgeReferralRepo
    implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeBridgeReferralRepo(
    Map<String, PhysiotherapyReferral> byId, {
    this.throwOnUpdate = false,
    this.throwOnGetById = false,
  }) : _byId = Map.of(byId);

  final Map<String, PhysiotherapyReferral> _byId;
  final bool throwOnUpdate;
  final bool throwOnGetById;

  int updateCallCount = 0;
  PhysiotherapyReferralSafeUpdate? lastUpdate;

  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (throwOnGetById) {
      throw StateError('getById failed');
    }
    return _byId[id];
  }

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async {
    updateCallCount++;
    lastUpdate = update;
    if (throwOnUpdate) {
      throw StateError('update failed');
    }
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
  }) async =>
      [];

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;
}

void main() {
  tearDown(() {
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  group('computeTargetStatus', () {
    test('yeni without notification → devam', () {
      expect(
        PhysiotherapyReferralStatusBridgeDataSource.computeTargetStatus(
          current: ReferralStatus.yeni,
          doctorNotificationNeeded: false,
        ),
        ReferralStatus.devam,
      );
    });

    test('notification true escalates from yeni', () {
      expect(
        PhysiotherapyReferralStatusBridgeDataSource.computeTargetStatus(
          current: ReferralStatus.yeni,
          doctorNotificationNeeded: true,
        ),
        ReferralStatus.doktor_degerlendirmesi_bekliyor,
      );
    });

    test('notification true escalates from devam', () {
      expect(
        PhysiotherapyReferralStatusBridgeDataSource.computeTargetStatus(
          current: ReferralStatus.devam,
          doctorNotificationNeeded: true,
        ),
        ReferralStatus.doktor_degerlendirmesi_bekliyor,
      );
    });

    test('devam without notification → no change', () {
      expect(
        PhysiotherapyReferralStatusBridgeDataSource.computeTargetStatus(
          current: ReferralStatus.devam,
          doctorNotificationNeeded: false,
        ),
        isNull,
      );
    });

    test('tamamlandi and iptal are protected', () {
      for (final terminal in [
        ReferralStatus.tamamlandi,
        ReferralStatus.iptal,
      ]) {
        expect(
          PhysiotherapyReferralStatusBridgeDataSource.computeTargetStatus(
            current: terminal,
            doctorNotificationNeeded: false,
          ),
          isNull,
        );
        expect(
          PhysiotherapyReferralStatusBridgeDataSource.computeTargetStatus(
            current: terminal,
            doctorNotificationNeeded: true,
          ),
          isNull,
        );
      }
    });

    test('already doktor_degerlendirmesi_bekliyor with notification → idempotent',
        () {
      expect(
        PhysiotherapyReferralStatusBridgeDataSource.computeTargetStatus(
          current: ReferralStatus.doktor_degerlendirmesi_bekliyor,
          doctorNotificationNeeded: true,
        ),
        isNull,
      );
    });
  });

  group('syncAfterSessionCreate', () {
    test('empty referralId is no-op', () async {
      final repo = _FakeBridgeReferralRepo({_referralId: _referral()});
      PhysiotherapyReferralRepositoryProvider.testOverride = repo;

      await PhysiotherapyReferralStatusBridgeDataSource.syncAfterSessionCreate(
        referralId: '  ',
        doctorNotificationNeeded: false,
      );

      expect(repo.updateCallCount, 0);
    });

    test('yeni + no notification updates to devam and marks stale', () async {
      final repo = _FakeBridgeReferralRepo({_referralId: _referral()});
      PhysiotherapyReferralRepositoryProvider.testOverride = repo;
      final versionBefore = PhysiotherapyReferralListRefresh.version;

      await PhysiotherapyReferralStatusBridgeDataSource.syncAfterSessionCreate(
        referralId: _referralId,
        doctorNotificationNeeded: false,
      );

      expect(repo.updateCallCount, 1);
      expect(repo.lastUpdate?.status, ReferralStatus.devam);
      expect(repo.lastUpdate?.notesSafe, isNull);
      expect(repo.lastUpdate?.plannedStartDate, isNull);
      expect(
        PhysiotherapyReferralListRefresh.version,
        greaterThan(versionBefore),
      );
    });

    test('notification true sets doktor_degerlendirmesi_bekliyor', () async {
      final repo = _FakeBridgeReferralRepo({
        _referralId: _referral(status: ReferralStatus.devam),
      });
      PhysiotherapyReferralRepositoryProvider.testOverride = repo;

      await PhysiotherapyReferralStatusBridgeDataSource.syncAfterSessionCreate(
        referralId: _referralId,
        doctorNotificationNeeded: true,
      );

      expect(repo.updateCallCount, 1);
      expect(
        repo.lastUpdate?.status,
        ReferralStatus.doktor_degerlendirmesi_bekliyor,
      );
    });

    test('tamamlandi is not updated', () async {
      final repo = _FakeBridgeReferralRepo({
        _referralId: _referral(status: ReferralStatus.tamamlandi),
      });
      PhysiotherapyReferralRepositoryProvider.testOverride = repo;

      await PhysiotherapyReferralStatusBridgeDataSource.syncAfterSessionCreate(
        referralId: _referralId,
        doctorNotificationNeeded: false,
      );

      expect(repo.updateCallCount, 0);
    });

    test('update failure is swallowed', () async {
      final repo = _FakeBridgeReferralRepo(
        {_referralId: _referral()},
        throwOnUpdate: true,
      );
      PhysiotherapyReferralRepositoryProvider.testOverride = repo;

      await expectLater(
        PhysiotherapyReferralStatusBridgeDataSource.syncAfterSessionCreate(
          referralId: _referralId,
          doctorNotificationNeeded: false,
        ),
        completes,
      );
      expect(repo.updateCallCount, 1);
    });

    test('getById failure is swallowed', () async {
      final repo = _FakeBridgeReferralRepo(
        {_referralId: _referral()},
        throwOnGetById: true,
      );
      PhysiotherapyReferralRepositoryProvider.testOverride = repo;

      await expectLater(
        PhysiotherapyReferralStatusBridgeDataSource.syncAfterSessionCreate(
          referralId: _referralId,
          doctorNotificationNeeded: false,
        ),
        completes,
      );
      expect(repo.updateCallCount, 0);
    });
  });

  test('bridge source does not touch clinical encounter or notes_safe', () {
    final bridgeSource = File(
      'lib/features/physiotherapy/data/physiotherapy_referral_status_bridge_data_source.dart',
    ).readAsStringSync();

    expect(bridgeSource.contains('internalDoctorNote'), isFalse);
    expect(bridgeSource.contains('clinicalEncountersAsync'), isFalse);
    expect(bridgeSource.contains('notesSafe:'), isFalse);
    expect(bridgeSource.contains('doctorSummary'), isFalse);
    expect(bridgeSource.contains('PhysiotherapyReferralSafeUpdate'), isTrue);
  });
}
