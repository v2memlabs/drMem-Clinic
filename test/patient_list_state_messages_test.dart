import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_list_state_messages.dart';

void main() {
  test('empty db title when query blank', () {
    expect(
      PatientListStateMessages.emptyTitle(query: ''),
      PatientListStateMessages.emptyDbTitle,
    );
  });

  test('search empty title when query set', () {
    expect(
      PatientListStateMessages.emptyTitle(query: 'ali'),
      PatientListStateMessages.emptySearchTitle,
    );
  });
}
