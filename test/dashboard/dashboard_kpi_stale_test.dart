import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/remote_list_refresh_coordinator.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_list_refresh.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_refresh.dart';
import 'package:v2mem_clinic/features/consents/data/consent_list_refresh.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_list_refresh.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_list_refresh.dart';

/// Dashboard ve liste ekranları — stale gate birim smoke.
void main() {
  group('Dashboard KPI stale gates', () {
    test('InventoryListRefresh stale after markStale', () {
      final seen = InventoryListRefresh.version;
      InventoryListRefresh.markStale();
      expect(InventoryListRefresh.isStale(seen), isTrue);
    });

    test('ConsentListRefresh stale after markStale', () {
      final seen = ConsentListRefresh.version;
      ConsentListRefresh.markStale();
      expect(ConsentListRefresh.isStale(seen), isTrue);
    });

    test('PhysiotherapyReferralListRefresh stale after markStale', () {
      final seen = PhysiotherapyReferralListRefresh.version;
      PhysiotherapyReferralListRefresh.markStale();
      expect(PhysiotherapyReferralListRefresh.isStale(seen), isTrue);
    });

    test('PhysiotherapySessionListRefresh stale after markStale', () {
      final seen = PhysiotherapySessionListRefresh.version;
      PhysiotherapySessionListRefresh.markStale();
      expect(PhysiotherapySessionListRefresh.isStale(seen), isTrue);
    });
  });

  group('RemoteListRefreshCoordinator session scope', () {
    test('markAllStale includes clinical encounter and assistant summary',
        () {
      final clinical = ClinicalEncounterListRefresh.version;
      final assistant = AssistantClinicalSummaryListRefresh.version;
      final sessions = PhysiotherapySessionListRefresh.version;

      RemoteListRefreshCoordinator.markAllStale();

      expect(
        ClinicalEncounterListRefresh.version,
        greaterThan(clinical),
      );
      expect(
        AssistantClinicalSummaryListRefresh.version,
        greaterThan(assistant),
      );
      expect(
        PhysiotherapySessionListRefresh.version,
        greaterThan(sessions),
      );
    });
  });
}
