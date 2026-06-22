import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_clinical_handoff_data_source.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

void main() {
  test('prepareForClinicalEncounter updates planlandi to geldi', () async {
    final original = AppointmentRepository.instance.getById('a10');
    expect(original, isNotNull);
    expect(original!.status, AppointmentStatus.planlandi);

    final result = await AppointmentClinicalHandoffDataSource
        .prepareForClinicalEncounter(original);
    expect(result.status, AppointmentStatus.geldi);

    final stored = AppointmentRepository.instance.getById('a10');
    expect(stored?.status, AppointmentStatus.geldi);

    AppointmentRepository.instance.update(
      Appointment(
        id: original.id,
        patientId: original.patientId,
        patientName: original.patientName,
        appointmentDateTime: original.appointmentDateTime,
        durationMinutes: original.durationMinutes,
        type: original.type,
        status: AppointmentStatus.planlandi,
        reason: original.reason,
        controlDate: original.controlDate,
        notes: original.notes,
      ),
    );
  });

  test('prepareForClinicalEncounter leaves geldi unchanged', () async {
    final original = AppointmentRepository.instance.getById('a2');
    expect(original, isNotNull);
    expect(original!.status, AppointmentStatus.geldi);

    final result = await AppointmentClinicalHandoffDataSource
        .prepareForClinicalEncounter(original);
    expect(result.status, AppointmentStatus.geldi);
  });
}
