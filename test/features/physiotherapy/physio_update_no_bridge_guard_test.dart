import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('physio referral updateSafeFields path does not call FTR bridge', () {
    final detailSource = File(
      'lib/features/physiotherapy/data/physiotherapy_referral_detail_data_source.dart',
    ).readAsStringSync();
    final formSource = File(
      'lib/features/physiotherapy/data/physiotherapy_referral_form_data_source.dart',
    ).readAsStringSync();

    expect(detailSource.contains('ClinicalEncounterFtrBridgeDataSource'), isFalse);
    expect(detailSource.contains('clinical_encounter_ftr_bridge'), isFalse);
    expect(detailSource.contains('clinicalEncountersAsync.update'), isFalse);

    expect(formSource.contains('ClinicalEncounterFtrBridgeDataSource'), isTrue);
    expect(formSource.contains('syncReferralFlagAfterReferralCreate'), isTrue);
  });

  test('bridge data source does not import referral detail update', () {
    final bridgeSource = File(
      'lib/features/clinical_encounter/data/clinical_encounter_ftr_bridge_data_source.dart',
    ).readAsStringSync();

    expect(bridgeSource.contains('updateSafeFields'), isFalse);
    expect(bridgeSource.contains('PhysiotherapyReferral'), isFalse);
    expect(bridgeSource.contains('notes_safe'), isFalse);
    expect(bridgeSource.contains('doctorSummary'), isFalse);
    expect(bridgeSource.contains('internalDoctorNote: e.internalDoctorNote'), isTrue);
  });
}
