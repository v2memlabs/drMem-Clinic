import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('patient detail rehab summary uses async data sources', () {
    final patientDetail = File('lib/features/patients/patient_detail_screen.dart')
        .readAsStringSync();
    final dataSource = File(
      'lib/features/physiotherapy/data/patient_rehab_referral_summary_data_source.dart',
    ).readAsStringSync();
    final sessionDisplay = File(
      'lib/features/physiotherapy/data/patient_rehab_last_session_display.dart',
    ).readAsStringSync();

    expect(
      patientDetail.contains('PatientRehabReferralSummaryDataSource.loadSummary'),
      isTrue,
    );
    expect(
      patientDetail.contains('PhysiotherapyRepository.instance.getSessionNotes'),
      isFalse,
    );
    expect(
      patientDetail.contains('ExercisePlanRepository.instance'),
      isFalse,
    );
    expect(dataSource.contains('physiotherapySessionsAsync'), isTrue);
    expect(dataSource.contains('getByReferralId'), isTrue);
    expect(
      dataSource.contains('PhysiotherapyRepository.instance'),
      isFalse,
    );

    expect(sessionDisplay.contains('.notes'), isFalse);
    expect(sessionDisplay.contains('exercisesPerformed'), isFalse);
    expect(sessionDisplay.contains('rangeOfMotionSummary'), isFalse);
    expect(sessionDisplay.contains('strengthSummary'), isFalse);
    expect(sessionDisplay.contains('internalDoctorNote'), isFalse);
    expect(sessionDisplay.contains('clinical_data'), isFalse);
  });

  test('rehab summary data source does not expose internal doctor fields', () {
    final displaySource = File(
      'lib/features/physiotherapy/data/patient_rehab_referral_summary_data_source.dart',
    ).readAsStringSync();

    expect(displaySource.contains('internalDoctorNote'), isFalse);
    expect(displaySource.contains('clinical_data'), isFalse);
  });
}
