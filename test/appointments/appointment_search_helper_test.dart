import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_search_helper.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

Appointment _appt({required String name, String notes = ''}) {
  return Appointment(
    id: 'a1',
    patientId: 'p1',
    patientName: name,
    appointmentDateTime: DateTime(2026, 5, 21, 10),
    durationMinutes: 30,
    type: AppointmentType.kontrol,
    status: AppointmentStatus.planlandi,
    reason: 'neden',
    notes: notes,
  );
}

void main() {
  test('empty query returns all', () {
    final list = [_appt(name: 'Ali')];
    expect(AppointmentSearchHelper.filter(list, ''), list);
  });

  test('filters by patient name', () {
    final list = [
      _appt(name: 'Ali Veli'),
      _appt(name: 'Ayşe Yılmaz'),
    ];
    final result = AppointmentSearchHelper.filter(list, 'ayşe');
    expect(result, hasLength(1));
    expect(result.first.patientName, 'Ayşe Yılmaz');
  });

  test('does not search reason field', () {
    final list = [_appt(name: 'Ali', notes: '')];
    expect(AppointmentSearchHelper.filter(list, 'neden'), isEmpty);
  });
}
