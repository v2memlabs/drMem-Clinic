import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_demo_count_label.dart';
import 'package:v2mem_clinic/core/product/demo_freemium_config.dart';

void main() {
  test('count format includes limit', () {
    expect(
      PatientDemoCountLabel.format(count: 2, limit: 3),
      '2 / 3 demo limit',
    );
  });

  test('over limit note mentions next phase', () {
    final note = PatientDemoCountLabel.limitNote(count: 4, limit: 3);
    expect(note, contains(DemoFreemiumConfig.patientLimitNote));
    expect(note, contains('SaaS'));
  });
}
