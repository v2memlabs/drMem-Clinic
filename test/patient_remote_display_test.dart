import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_remote_display.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';

void main() {
  test('isMeaningfulText rejects placeholder values', () {
    expect(PatientRemoteDisplay.isMeaningfulText(''), isFalse);
    expect(PatientRemoteDisplay.isMeaningfulText('-'), isFalse);
    expect(
      PatientRemoteDisplay.isMeaningfulText(Patient.unspecifiedLabel),
      isFalse,
    );
    expect(PatientRemoteDisplay.isMeaningfulText('Ayşe'), isTrue);
  });
}
